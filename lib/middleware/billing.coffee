_ = require 'lodash'
debug = require('debug')('tltbill_bot:billing')
config = require 'config'
request = require 'request'
urlJoin = require 'url-join'
Promise = require 'promise'
xml2js = require 'xml2js'
memory = require './memory'
auth = require '../models/authorize'

# INIT PARSER XML
parser = new xml2js.Parser()

###
# REQUEST CLIENT TO Billing API
# @param {number} ChatID
# @returns {*}
###
module.exports = (ChatID) ->
  ###
  # Ensure that access token has fetched
  # @returns {Promise}
  ###
  _ensureAccessToken = ->
    self = this
    Promise.resolve()
      .then ->
        token = memory.getToken ChatID
        if token
          self.accessToken = token
          return token

        self.accessToken = null
        _fetchAccessToken()

  ###
  # Fetch access token (SESSION_ID)
  # @returns {Promise}
  ###
  _fetchAccessToken = ->
    self = this
    _sendRequest('GET')
      .then ->
        memory.setToken(ChatID,self.accessToken)
        _authorized()

  ###
  # Request Authorize user to billing
  # @returns {Promise}
  ###
  _authorized = ->
    self = this
    new Promise (resolve, reject) ->
      auth.fetchPersona(config.users[ChatID])
        .then (data) ->
          _sendRequest('POST', '/ajax/index/authfl', data)
            .then (result) ->
              if result and result.user[0] and result.user[0].enable[0] == '1'
                return resolve()

              self.accessToken = null
              reject()
        .catch (err) ->
          console.log err
          self.accessToken = null
          reject()

  ###
  # Create request uri from API host address and passed path
  # @param {string} path
  # @private
  ###
  _createRequestUri = (path) ->
    urlJoin config.server.host, if path then path else ''

  ###
  # @param method
  # @param data
  # @private
  ###
  _createRequestOptions = (method, data) ->
    result = {}
    result.method = method
    result.form = data or {}
    if this.accessToken
      result.headers = Cookie: this.accessToken
    result

  ###
  # Send request to API server
  # @param {string} method Request method
  # @param {string} path Repository API path
  # @param {Object} [data] Request data
  # @private {Promise.<Object|Array,Error>} Response object (or array) if fulfilled or Error if rejected
  ###
  _sendRequest = (method, path, data) ->
    self = this
    requestUri = _createRequestUri(path)
    requestOptions = _createRequestOptions(method, data)
    new Promise (resolve, reject) ->
      logData = _.extend({}, requestOptions || {})
      if logData.headers
        delete logData.headers
      debug(requestUri+ ' Options: ' + JSON.stringify(logData))

      request requestUri,requestOptions, (error, response, body) ->
        if error
          console.log error
          return reject()

        # Если получен токен сохраняем и отвечаем
        if response.headers['set-cookie']
          self.accessToken = response.headers['set-cookie'][0].replace('; path=/', '')
          return resolve()

        # Если нет ответа
        if !body
          return reject()

        # Parse XML body
        parser.parseString '<xml>' +body+ '</xml>', (err, result) ->
          if err
            console.log err
            return reject()
          resolve result.xml
        return

  {
    # Token for Authorize
    accessToken: null

    ###
    # Pay User
    # @param uid
    # @param deposit
    ###
    PaymentUser: (uid,deposit) ->
     _ensureAccessToken().then ->
       _sendRequest('POST', '/ajax/users/paymentflex', {
         uid: uid
         deposit: deposit
         prim2: 'Оплачено'
      })
  }