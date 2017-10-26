const _ = require('lodash'),
    debug = require('debug')('tltbill_bot:billing'),
    config = require('config'),
    request = require('request'),
    urlJoin = require('url-join'),
    xml2js = require('xml2js'),
    parser = new xml2js.Parser();

// Services
const memory = require('../services/memory');
// Models
const auth = require('../models/authorize');

/**
 * REQUEST CLIENT TO Billing API
 * @param {number} ChatID
 * @returns {*}
 */
module.exports = function (ChatID) {
    /* Access Token */
    let accessToken = null;

    // REQUESTS
    return {
        /**
         * Pay User Balance
         * @param uid
         * @param deposit
         * @returns {Promise}
         */
        PaymentUserBalance: (uid, deposit) => {
            return _ensureAccessToken().then(() => {
                return _sendRequest('POST', '/ajax/users/paymentflex', {
                    uid: uid,
                    deposit: deposit,
                    prim2: 'Оплачено'
                });
            });
        },

        /**
         * Pull User Balance
         * @param uid
         * @param deposit
         * @returns {Promise}
         */
        PullUserBalance: (uid, deposit) => {
            return _ensureAccessToken().then(() => {
                return _sendRequest('POST', '/ajax/users/paymentdoflex', {
                    uid: uid,
                    deposit: deposit,
                    prim2: 'Оператором',
                    bughtypeid: 7
                });
            });
        },

        /**
         * Credit User
         * @param uid
         * @param sum or off
         * @returns {Promise}
         */
        CreditUser: (uid, sum) => {
            let url = '/ajax/users/creditfl';

            // Credit off
            if (sum === 'off')
                url = '/ajax/users/creditnullfl';

            return _ensureAccessToken().then(() => {
                return _sendRequest('POST', url, {
                    uid: uid,
                    credit: sum
                });
            });
        }
    };

    /**
     * Ensure that access token has fetched
     * @returns {Promise}
     */
    function _ensureAccessToken() {
        return Promise.resolve().then(() => {
            const token = memory.getToken(ChatID);
            accessToken = null;

            if (token) {
                accessToken = token;
                return token;
            }

            return _fetchAccessToken();
        });
    }

    /**
     * Fetch access token (SESSION_ID)
     * @returns {Promise}
     */
    function _fetchAccessToken() {
        return _sendRequest('GET').then(() => {
            memory.setToken(ChatID, accessToken);
            return _authorized();
        });
    }

    /**
     * Request Authorize user to billing
     * @returns {Promise}
     */
    function _authorized() {
        return new Promise((resolve, reject) => {
            return auth.fetchPersona(config.users[ChatID])
                .then(data => {
                    return _sendRequest('POST', '/ajax/index/authfl', data).then(result => {
                        if (result && result.user[0] && result.user[0].enable[0] === '1')
                            return resolve();

                        accessToken = null;
                        reject();
                    });
                }).catch(err => {
                    console.log(err);
                    accessToken = null;
                    return reject();
                });
        });
    }

    /**
     * Create request uri from API host address and passed path
     * @param {string} path
     * @private
     */
    function _createRequestUri(path) {
        return urlJoin(config.server.host, path ? path : '');
    }

    /**
     * Create request option
     * @param method
     * @param data
     * @private
     */
    function _createRequestOptions(method, data) {
        let result = {
            method: method,
            form: data || {}
        };

        // IF AccessToken - add to headers this
        if (accessToken) result.headers = {Cookie: accessToken};

        // Return
        return result;
    }

    /**
     * Send request to API server
     * @param {string} method Request method
     * @param {string} [path] Repository API path
     * @param {Object} [data] Request data
     * @private {Promise.<Object|Array,Error>} Response object (or array) if fulfilled or Error if rejected
     */
    function _sendRequest(method, path, data) {
        const requestUri = _createRequestUri(path),
            requestOptions = _createRequestOptions(method, data);

        return new Promise((resolve, reject) => {
            let logData = _.extend({}, requestOptions || {});
            if (logData.headers) delete logData.headers;
            debug(requestUri + ' Options: ' + JSON.stringify(logData));

            return request(requestUri, requestOptions, (err, response, body) => {
                if (err) {
                    console.log(err);
                    return reject();
                }
                // IF YES Cookie - save
                if (response.headers['set-cookie']) {
                    accessToken = response.headers['set-cookie'][0].replace('; path=/', '');
                    return resolve();
                }
                // IF null body return
                if (!body) return reject();

                parser.parseString('<xml>' + body + '</xml>', (err, result) => {
                    if (err) {
                        console.log(err);
                        return reject();
                    }
                    return resolve(result.xml);
                });
            });
        });
    }
};
