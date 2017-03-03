config = require 'config'
NodeCache = require 'node-cache'
memory = new NodeCache()

###
# GET Memory db
# @return {*}
###
module.exports = {
    ###
    # GET TOKEN User
    # @param {number} ChatID
    ###
    getToken: (ChatID) ->
      memory.get(ChatID) or null

    ###
    # Save Token User
    # @param {number} ChatID
    # @param {Object} data
    ###
    setToken: (ChatID,token) ->
      memory.set ChatID, token, config.tokenTTL

    ###
    # Update TOKEN TTL
    # @param {number} ChatID
    ###
    updTokenTTL: (ChatID) ->
      memory.ttl ChatID, config.tokenTTL
  }