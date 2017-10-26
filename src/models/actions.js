const billing = require('../services/billing');

module.exports = {
    /**
     * Payment Balance User
     * @param {Array} args
     * @param {number} userID
     * @return {Promise}
     */
    PaymentUserBalance: (args, userID) => {
        return new Promise((resolve, reject) => {
            billing(userID).PaymentUserBalance(args[0], args[1])
                .then(data => {
                    if (data && data.ok[0] === '1')
                        return resolve('UID: *' + args[0] + '*\nПополнение на сумму *' + args[1] + '*р\nСтатус: *Успешно*');

                    reject();
                }).catch(err => reject(err));
        });
    },

    /**
     * Pull Balance User
     * @param {Array} args
     * @param {number} userID
     * @return {Promise}
     */
    PullUserBalance: (args, userID) => {
        return new Promise((resolve, reject) => {
            billing(userID).PullUserBalance(args[0], args[1])
                .then(data => {
                    if (data && data.ok[0] === '1')
                        return resolve('UID: *' + args[0] + '*\nСнятие суммы *' + args[1] + '*р\nСтатус: *Успешно*');

                    reject();
                }).catch(err => reject(err));
        });
    },

    /**
     * Credit Disable User
     * @param {Array} args
     * @param {number} userID
     * @return {Promise}
     */
    CreditUser: (args, userID) => {
        return new Promise((resolve, reject) => {
            billing(userID).CreditUser(args[0], args[1])
                .then(data => {
                    let text;
                    if (data && data.username || data && data.ok[0] === '1') {
                        text = 'UID: *' + args[0] + '*\nАктивация кредита *' + args[1] + '* р\nСтатус: *Успешно*';

                        if (args[1] === 'off')
                            text = 'UID: *' + args[0] + '*\nОтключение кредита\nСтатус: *Успешно*';

                        return resolve(text);
                    }

                    reject();
                }).catch(err => reject(err));
        });
    }
};