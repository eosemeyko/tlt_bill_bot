_ = require 'lodash'
debug = require('debug')('tltbill_bot:mysql')
config = require 'config'
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
          console.log err
          return reject err
        debug 'good request'
        resolve rows
        return
      return
}
