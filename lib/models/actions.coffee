Promise = require 'promise'
billing = require '../middleware/billing'

module.exports = {
  ###
  # Payment User
  # @param {Array} args
  # @param userID
  # @return {Promise}
  ###
  PaymentUser: (args,userID) ->
    new Promise (resolve, reject) ->
      # args[0] - UID
      # args[1] - SUM
      billing(userID).PaymentUser(args[0],args[1])
        .then (data) ->
          if data and data.ok[0] == '1'
            deposit = Math.floor(data.deposit[0])
            resolve 'Статус: *Успешно*\nUID: *' +args[0]+ '*\nБаланс: *' +deposit+ ' руб*'
          else reject()
        .catch (err) ->
          reject err
      return
}