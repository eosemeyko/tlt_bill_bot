const debug = require('debug')('tltbill_bot:mysql'),
    config = require('config'),
    mysql = require('mysql'),
    db = mysql.createPool(config.db);

module.exports = {
    /**
     * Query request to DB
     * @param request
     * @return {Promise}
     */
    query: (request) => {
        return new Promise((resolve, reject) => {
            db.query(request, (err, rows) => {
                if (err) {
                    debug(err);
                    return reject(err);
                }

                debug('good request');
                resolve(rows);
            });
        });
    }
};
