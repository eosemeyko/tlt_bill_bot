Promise = require 'promise'
billing = require '../middleware/billing'

module.exports = {
  ###
  # Payment Balance User
  # @param {Array} args
  # @param userID
  # @return {Promise}
  ###
  PaymentUserBalance: (args,userID) ->
    new Promise (resolve, reject) ->
      # args[0] - UID
      # args[1] - SUM
      billing(userID).PaymentUserBalance(args[0],args[1])
        .then (data) ->
          if data and data.ok[0] == '1'
            resolve 'UID: *' +args[0]+ '*\nПополнение на сумму *' +args[1]+ '*р\nСтатус: *Успешно*'
          else reject()
        .catch (err) ->
          reject err
      return

  ###
  # Pull Balance User
  # @param {Array} args
  # @param userID
  # @return {Promise}
  ###
  PullUserBalance: (args,userID) ->
    new Promise (resolve, reject) ->
      # args[0] - UID
      # args[1] - SUM
      billing(userID).PullUserBalance(args[0],args[1])
        .then (data) ->
          if data and data.ok[0] == '1'
            resolve 'UID: *' +args[0]+ '*\nСнятие суммы *' +args[1]+ '*р\nСтатус: *Успешно*'
          else reject()
        .catch (err) ->
          reject err
      return

  ###
  # Credit Disable User
  # @param {Array} args
  # @param userID
  # @return {Promise}
  ###
  CreditUser: (args,userID) ->
    new Promise (resolve, reject) ->
      # args[0] - UID
      # args[1] - SUM || off
      billing(userID).CreditUser(args[0],args[1])
        .then (data) ->
          if data and data.username or data and data.ok[0] == '1'
            text = 'UID: *' +args[0]+ '*\nАктивация кредита *' +args[1]+ '* р\nСтатус: *Успешно*'
            text = 'UID: *' +args[0]+ '*\nОтключение кредита\nСтатус: *Успешно*' if args[1] == 'off'
            resolve text
          else reject()
        .catch (err) ->
          reject err
      return

}