_ = require 'lodash'
config = require 'config'
Promise = require 'promise'
mysql = require 'mysql'
db = mysql.createConnection config.db

module.exports = {
  ###
  # Query request to MySQL
  # @param request
  # @return {Promise}
  ###
  query: (request) ->
    new Promise (resolve, reject) ->
      db.query request, (err, rows) ->
        if err
          reject err
        resolve rows
        return
      return
}
