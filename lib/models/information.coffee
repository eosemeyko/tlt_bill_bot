_ = require 'lodash'
async = require 'async'
Promise = require 'promise'
db = require '../middleware/mysql'
billing = require '../middleware/billing'
dateFormat = require 'dateformat'
debug = require('debug')('tltbill_bot:information')

module.exports = {
  ###
  # Fetch Lanes
  # @return {Promise}
  ###
  fetchLanes: ->
    new Promise (resolve, reject) ->
      db.query('SELECT * FROM `lanes`')
        .then (data) ->
          if _.isEmpty(data)
            debug 'fetchLanes:isEmpty'
            return resolve()

          array = []
          async.each data, (value,callback) ->
            array.push
              text: value.lane
              callback_data: 'select_lane '+value.laneid
            callback()
          , ->
            debug 'fetchLanes:GOOD'
            resolve(
              buttons: array
            )
          return
        .catch (err) ->
          debug 'fetchLanes:ERROR '+err
          reject err
      return


  ###
  # Fetch Houses
  # @param lane_id
  # @return {Promise}
  ###
  fetchHouses: (lane_id) ->
    new Promise (resolve, reject) ->
      db.query('SELECT * FROM `lanes_houses` WHERE `laneid`=' + lane_id[0])
        .then (data) ->
          if _.isEmpty(data)
            debug 'fetchHouses:isEmpty'
            return resolve()

          array = []
          async.each data, (value,callback) ->
            array.push
              text: value.house
              callback_data: 'select_house '+value.houseid
            callback()
          ,() ->
            debug 'fetchHouses:GOOD'
            resolve array
          return
        .catch (err) ->
          debug 'fetchHouses:ERROR '+err
          reject err
      return

  ###
  # Fetch Users in this House
  # @param house_id
  # @return {Promise}
  ###
  fetchHouseUsers: (house_id) ->
    new Promise (resolve, reject) ->
      users = "SELECT `users`.`uid`,`users`.`user`, `users`.`fio`, `users`.`deposit`, `users`.`credit`,'norm' AS `status`,
      if(`inetonline`.`uid`,'ON','OFF') AS `online`,
      if(`inetonline`.`uid`,NULL,(SELECT `acctstoptime` FROM `radacct` WHERE `radacct`.`uid` = `users`.`uid` ORDER BY `radacctid` DESC LIMIT 1)) AS `acctstoptime`
      FROM `users`
      left join `inetonline` on(`users`.`uid` = `inetonline`.`uid`)
      WHERE `houseid` =" + house_id[0]
      users_block = "SELECT `uid`,`user`,`fio`,`deposit`,`credit`,'otkl' AS `status`,NULL AS `online`,NULL AS `acctstoptime` FROM `usersblok` WHERE `houseid` =" + house_id[0]
      users_del = "SELECT `uid`,`user`,`fio`,`deposit`,`credit`,'del' AS `status`,NULL AS `online`,NULL AS `acctstoptime` FROM `usersdel` WHERE `houseid` =" + house_id[0]

      db.query(users + ' UNION ' + users_block + ' UNION ' + users_del)
        .then (data) ->
          if _.isEmpty(data)
            debug 'fetchHouseUsers:isEmpty'
            return resolve()

          result = []
          async.each data, (value,callback) ->
          # DEPOSIT
            deposit = ', Б:*' +Math.floor(value.deposit)+ '*'
            # ONLINE
            if value.online
              online = ', *' +value.online + '*'
            else online = ''
            # FIO
            if value.fio
              fio = ', Ф:*' + value.fio + '*'
            else fio = ''
            # CREDIT
            if value.credit != 0 and value.credit != 0.00
              credit = ', Кр:*' +value.credit + '*'
            else credit = ''
            # STATUS
            if value.status != 'norm'
              status = ', С:*' + value.status + '*'
            else status = ''
            # ACT stop date
            if value.status == 'norm' and value.online == 'OFF' and value.acctstoptime
              act = ', ' +dateFormat(value.acctstoptime, "d/m/yy HH:MM")
            else act = ''

            # Compile
            result.push('U:*' +value.uid+ '*, Л:*' +value.user+ '*' +fio+deposit+credit+status+online+act)
            callback()
          ,() ->
            debug 'fetchHouseUsers:GOOD'
            resolve _.join(result, '\n-----------------------------------------\n')
          return
        .catch (err) ->
          debug 'fetchHouseUsers:ERROR '+err
          reject err
      return

  ###
  # Fetch User Balance
  # @param {Array} args - Arguments
  # @return {Promise}
  ###
  fetchUserBalance: (args) ->
    new Promise (resolve, reject) ->
      users = "SELECT user,deposit,NULL AS status,`packets`.`packet` FROM `users` left join `packets` on(`users`.`gid` = `packets`.`gid`) WHERE `uid`=" + args[0]
      usersblock =  "SELECT user,deposit,'otkl' as status,`packets`.`packet` FROM `usersblok` left join `packets` on(`usersblok`.`gid` = `packets`.`gid`) WHERE `uid`=" + args[0]
      usersdel = "SELECT user,deposit,'del' as status,`packets`.`packet` FROM `usersdel` left join `packets` on(`usersdel`.`gid` = `packets`.`gid`) WHERE `uid`=" + args[0]
      db.query(users+ ' UNION ' +usersblock+ ' UNION ' +usersdel)
        .then (data) ->
          if _.isEmpty(data)
            debug 'fetchUserBalance:isEmpty'
            return resolve()

          user = data[0]
          deposit = Math.floor(user.deposit)
          if args[2] == 'payment'
            sum = parseInt(deposit) + parseInt(args[1])
          else
            sum = parseInt(deposit) - parseInt(args[1])

          # STATUS
          if user.status
            text = if user.status == 'otkl' then 'Отключен' else 'Удален'
            status = 'Статус: *' +text + '*\n'
          else status = ''

          # RESULT COMPILE
          result = status+ 'UID: *' +args[0]+ '*\nЛогин: *' +user.user+ '*\nТариф: *' +user.packet+ '*\nБаланс до: *' +deposit+ ' руб*\nБаланс после: *' +sum+ '* руб'
          array = [
            {
              text: 'Выполнить'
              callback_data: args[2]+ ' ' +args[0]+ ' ' +args[1]
            }
            {
              text: 'Отменить'
              callback_data: 'cancel'
            }
          ]
          debug 'fetchUserBalance:GOOD'
          resolve(
            result: result
            buttons: array
          )
        .catch (err) ->
          debug 'fetchUserBalance:ERROR '+err
          reject err
      return

  ###
  # Fetch User
  # @param args - Arguments
  # @return {Promise}
  ###
  fetchUser: (args) ->
    new Promise (resolve, reject) ->
      fio = '%' +args+ '%'

      # USERS TABLE
      users = "SELECT `users`.`uid`,`users`.`user`,`users`.`password`,`users`.`deposit`,`users`.`local_ip`,NULL AS status,`users`.`fio`,`packets`.`packet`,
        if(`inetonline`.`uid`,'ON','OFF') AS `online`,
        if(`inetonline`.`uid`,NULL,(SELECT `acctstoptime` FROM `radacct` WHERE `radacct`.`uid` = `users`.`uid` ORDER BY `radacctid` DESC LIMIT 1)) AS `acctstoptime`,
        (SELECT `lane` FROM `lanes` WHERE `lanes`.`laneid` = `lanes_houses`.`laneid`) AS `lane`,`lanes_houses`.`house`, `users`.`app`
        FROM `users` left join `inetonline` on(`users`.`uid` = `inetonline`.`uid`) left join `packets` on(`users`.`gid` = `packets`.`gid`) left join `lanes_houses` on(`users`.`houseid` = `lanes_houses`.`houseid`)
        WHERE `users`.`uid`='" +args+ "' OR `users`.`user` LIKE '" +args+ "' OR `users`.`fio` LIKE '" +fio+ "' LIMIT 1"

      # USERS BLOCK TABLE
      users_block = "SELECT uid,user,password,deposit,local_ip,'otkl' as status,fio,`packets`.`packet`,'OFF' AS `online`,NULL AS `acctstoptime`,
        (SELECT `lane` FROM `lanes` WHERE `lanes`.`laneid` = `lanes_houses`.`laneid`) AS `lane`,`lanes_houses`.`house`, app
        FROM `usersblok` left join `packets` on(`usersblok`.`gid` = `packets`.`gid`) left join `lanes_houses` on(`usersblok`.`houseid` = `lanes_houses`.`houseid`)
        WHERE `uid`='" +args+ "' OR `user` LIKE '" +args+ "' OR `fio` LIKE '"+fio+ "' LIMIT 1"

      # USERS DELETE TABLE
      users_del = "SELECT uid,user,password,deposit,local_ip,'del' as status,fio,`packets`.`packet`,'OFF' AS `online`,NULL AS `acctstoptime`,
        (SELECT `lane` FROM `lanes` WHERE `lanes`.`laneid` = `lanes_houses`.`laneid`) AS `lane`,`lanes_houses`.`house`, app
        FROM `usersdel` left join `packets` on(`usersdel`.`gid` = `packets`.`gid`) left join `lanes_houses` on(`usersdel`.`houseid` = `lanes_houses`.`houseid`)
        WHERE `uid`='" +args+ "' OR `user` LIKE '" +args+ "' OR `fio` LIKE '" +fio+ "' LIMIT 1"

      # Query request to sql
      db.query(users+ ' UNION ' +users_block+ ' UNION ' +users_del)
        .then (data) ->
          if _.isEmpty(data)
            debug 'fetchUser:isEmpty'
            return resolve()
          user = data[0]
          deposit = Math.floor(user.deposit)

          # STATUS
          if user.status
            text = if user.status == 'otkl' then 'Отключен' else 'Удален'
            status = 'Статус: *' +text + '*\n'
          else status = ''

          # FIO
          if user.fio
            fio = '\nФИО: *' + user.fio + '*'
          else fio = ''

          # HOUSE ADDRESS
          if user.app
            house = '\nАдрес: *' + user.lane+ ' ' +user.house+ '/' +user.app + '*'
          else house = '\nАдрес: *' + user.lane+ ' ' +user.house + '*'

          # Online
          if user.online == 'ON'
            online = 'ДА'
          else online = 'НЕТ'

          # Connect
          if user.online == 'OFF' and user.acctstoptime
            date = dateFormat(user.acctstoptime, "d/m/yy HH:MM")
            connect = '\nКоннект: *' +date+ '*'
          else connect = ''

          # RESULT COMPILE
          result = 'UID: *' +user.uid+ '*\n' +status+ 'Логин: *' +user.user+ '*\nПароль: *' +user.password+ '*' +fio+house+ '\n\nТариф: *' +user.packet+ '*\nБаланс: *' +deposit+ ' руб*\n\nОнлайн: *' +online+ '*' +connect+ '\nIP адрес: *' +user.local_ip+ '*'

          debug 'fetchUser:GOOD'
          resolve(
            result: result
            buttons: []
          )
        .catch (err) ->
          debug 'fetchUser:ERROR '+err
          reject err
      return
}