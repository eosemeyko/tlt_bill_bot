_ = require 'lodash'
async = require 'async'
Promise = require 'promise'
db = require '../middleware/mysql'
billing = require '../middleware/billing'
dateFormat = require 'dateformat'

module.exports = {
  ###
  # Fetch Lanes
  # @return {Promise}
  ###
  fetchLanes: ->
    new Promise (resolve, reject) ->
      db.query('SELECT * FROM `lanes`')
        .then (data) ->
          if data.length > 0
            array = []
            async.each data, (value,callback) ->
              array.push
                text: value.lane
                callback_data: 'select_lane '+value.laneid
              callback()
            , ->
              resolve(
                buttons: array
              )
          else resolve()
        .catch (err) ->
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
          if data.length > 0
            array = []
            async.each data, (value,callback) ->
              array.push
                text: value.house
                callback_data: 'select_house '+value.houseid
              callback()
            ,() ->
              resolve array
          else resolve()
        .catch (err) ->
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
          if data.length > 0
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
              resolve _.join(result, '\n-----------------------------------------\n')
          else resolve()
        .catch (err) ->
          reject err
      return

  ###
  # Fetch User Payment
  # @param {Array} args - Arguments
  # @return {Promise}
  ###
  fetchUserBalance: (args) ->
    new Promise (resolve, reject) ->
      users = "SELECT user,deposit,NULL AS status FROM `users` WHERE `uid` =" + args[0]
      usersblock =  "SELECT user,deposit,'otkl' as status FROM `usersblok` WHERE `uid` =" + args[0]
      usersdel = "SELECT user,deposit,'del' as status FROM `usersdel` WHERE `uid` =" + args[0]
      db.query(users+ ' UNION ' +usersblock+ ' UNION ' +usersdel)
        .then (data) ->
          if data.length > 0
            user = data[0]
            deposit = Math.floor(user.deposit)
            sum = parseInt(deposit) + parseInt(args[1])
            # STATUS
            if user.status
              if user.status == 'otkl'
                status = 'Статус: *Отключен*\n'
              if user.status == 'del'
                status = 'Статус: *Удален*\n'
            else status = ''

            # RESULT COMPILE
            result = status+ 'UID: *' +args[0]+ '*\nЛогин: *' +user.user+ '*\nБаланс до: *' +deposit+ ' руб*\nБаланс после: *' +sum+ '* руб'
            array = [
              {
                text: 'Выполнить'
                callback_data: 'payment ' +args[0]+ ' ' +args[1]
              }
              {
                text: 'Отменить'
                callback_data: 'cancel'
              }
            ]
            resolve(
              result: result
              buttons: array
            )
          else resolve()
        .catch (err) ->
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
      users = "SELECT `users`.`uid`,`users`.`user`,`users`.`deposit`,NULL AS status,`users`.`fio`,
        if(`inetonline`.`uid`,'ON','OFF') AS `online`,
        if(`inetonline`.`uid`,NULL,(SELECT `acctstoptime` FROM `radacct` WHERE `radacct`.`uid` = `users`.`uid` ORDER BY `radacctid` DESC LIMIT 1)) AS `acctstoptime`
        FROM `users` left join `inetonline` on(`users`.`uid` = `inetonline`.`uid`)
        WHERE `users`.`uid`= '" +args+ "' OR `users`.`user` LIKE '" +args+ "' OR `users`.`fio` LIKE '" +fio+ "' LIMIT 1"
      usersblock = "SELECT uid,user,deposit,'otkl' as status,fio,'OFF' AS `online`,NULL AS `acctstoptime` FROM `usersblok` WHERE `uid`= '" +args+ "' OR `user` LIKE '" +args+ "' OR `fio` LIKE '"+fio+ "' LIMIT 1"
      usersdel = "SELECT uid,user,deposit,'del' as status,fio,'OFF' AS `online`,NULL AS `acctstoptime` FROM `usersdel` WHERE `uid`= '" +args+ "' OR `user` LIKE '" +args+ "' OR `fio` LIKE '" +fio+ "' LIMIT 1"
      db.query(users+ ' UNION ' +usersblock+ ' UNION ' +usersdel)
        .then (data) ->
          if data.length > 0
            user = data[0]
            deposit = Math.floor(user.deposit)

            # STATUS
            if user.status
              if user.status == 'otkl'
                status = 'Статус: *Отключен*\n'
              if user.status == 'del'
                status = 'Статус: *Удален*\n'
            else status = ''

            # FIO
            if user.fio
              fio = '\nФИО: *' + user.fio + '*'
            else fio = ''

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
            result = 'UID: *' +user.uid+ '*\n' +status+ 'Логин: *' +user.user+ '*' +fio+ '\nБаланс: *' +deposit+ ' руб*\nОнлайн: *' +online+ '*' +connect

            resolve(
              result: result
              buttons: []
            )
          else resolve()
        .catch (err) ->
          reject err
      return
}