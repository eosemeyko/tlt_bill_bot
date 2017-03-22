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
      token = memory.get(ChatID)
      if token
        memory.ttl ChatID, config.tokenTTL
        return token
      return null

    ###
    # Save Token User
    # @param {number} ChatID
    # @param {Object} data
    ###
    setToken: (ChatID,token) ->
      memory.set ChatID, token, config.tokenTTL
  }