const config = require('config'),
    NodeCache = require('node-cache'),
    memory = new NodeCache();

/**
 * Memory Requests
 * @return {*}
 */
module.exports = {
    /**
     * GET TOKEN
     * @param {number} ChatID
     * @returns {*}
     */
    getToken: (ChatID) => {
        const token = memory.get(ChatID);
        if (token) {
            memory.ttl(ChatID, config.tokenTTL || 1400);
            return token;
        }
        return null;
    },

    /**
     * SET Token
     * @param {number} ChatID
     * @param {Object} data
     */
    setToken: (ChatID, data) => {
        return memory.set(ChatID, data, config.tokenTTL || 1400);
    }
};