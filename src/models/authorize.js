const db = require('../services/mysql');

module.exports = {
    /*
     * Fetch Authorize Login and Pass
     * @param stuff_id
     * @return {Promise}
     */
    fetchPersona: (stuff_id) => {
        return new Promise((resolve, reject) => {
            db.query('SELECT * FROM `stuff_personal` WHERE stuffid =' + stuff_id)
                .then(data => {
                    if (data[0])
                        return resolve({
                            login: data[0].login,
                            password: data[0].pass
                        });

                    return reject();
                }).catch(err => reject(err));
        });
    }
};
