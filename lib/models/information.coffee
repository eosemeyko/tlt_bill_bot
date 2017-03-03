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
          if data
            array = []
            async.each data, (value,callback) ->
              array.push
                text: value.lane
                callback_data: 'select_lane '+value.laneid
              callback()
            , ->
              resolve array
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
          if data
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
          if data
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
}