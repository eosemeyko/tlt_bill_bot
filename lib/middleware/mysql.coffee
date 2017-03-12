_ = require 'lodash'
debug = require('debug')('tltbill_bot:mysql')
config = require 'config'
Promise = require 'promise'
mysql = require 'mysql'
db = mysql.createPool config.db

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
          debug err
          return reject err
        debug rows
        resolve rows
        return
      return
}
