const config = require('config'),
    users = config.users;

/**
 * Check User Access
 * @param ChatID
 * @returns {Boolean}
 */
module.exports = (ChatID) => {
    return !!(users && users[ChatID]);
};