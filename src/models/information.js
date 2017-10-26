const _ = require('lodash'),
    async = require('async'),
    dateFormat = require('dateformat'),
    debug = require('debug')('tltbill_bot:information');

// Services
const db = require('../services/mysql');

module.exports = {
    /**
     * Fetch Lanes
     * @return {Promise}
     */
    fetchLanes: function () {
        return new Promise((resolve, reject) => {
            db.query('SELECT * FROM `lanes`')
                .then(data => {
                    if (_.isEmpty(data)) {
                        debug('fetchLanes:isEmpty');
                        return resolve();
                    }
                    let array = [];
                    async.each(data, (value, callback) => {
                        array.push({
                            text: value.lane,
                            callback_data: 'select_lane ' + value.laneid
                        });
                        callback();
                    }, () => {
                        debug('fetchLanes:GOOD');
                        resolve({buttons: array});
                    });
                }).catch(err => {
                    debug('fetchLanes:ERROR ' + err);
                    return reject(err);
                });
        });
    },

    /**
     * Fetch Houses
     * @param lane_id
     * @return {Promise}
     */
    fetchHouses: function (lane_id) {
        return new Promise((resolve, reject) => {
            db.query('SELECT * FROM `lanes_houses` WHERE `laneid`=' + lane_id[0])
                .then(data => {
                    if (_.isEmpty(data)) {
                        debug('fetchHouses:isEmpty');
                        return resolve();
                    }
                    let array = [];
                    async.each(data, (value, callback) => {
                        array.push({
                            text: value.house,
                            callback_data: 'select_house ' + value.houseid
                        });
                        callback();
                    }, () => {
                        debug('fetchHouses:GOOD');
                        resolve(array);
                    });
                }).catch(err => {
                    debug('fetchHouses:ERROR ' + err);
                    reject(err);
                });
        });
    },

    /**
     * Fetch Users in this House
     * @param house_id
     * @return {Promise}
     */
    fetchHouseUsers: function (house_id) {
        return new Promise((resolve, reject) => {
            const users = "SELECT `users`.`uid`,`users`.`user`, `users`.`fio`, `users`.`deposit`, `users`.`credit`,'norm' AS `status`, if(`inetonline`.`uid`,'ON','OFF') AS `online`, if(`inetonline`.`uid`,NULL,(SELECT `acctstoptime` FROM `radacct` WHERE `radacct`.`uid` = `users`.`uid` ORDER BY `radacctid` DESC LIMIT 1)) AS `acctstoptime` FROM `users` left join `inetonline` on(`users`.`uid` = `inetonline`.`uid`) WHERE `houseid` =" + house_id[0],
                users_block = "SELECT `uid`,`user`,`fio`,`deposit`,`credit`,'otkl' AS `status`,NULL AS `online`,NULL AS `acctstoptime` FROM `usersblok` WHERE `houseid` =" + house_id[0];
            db.query(users + ' UNION ' + users_block)
                .then(data => {
                    if (_.isEmpty(data)) {
                        debug('fetchHouseUsers:isEmpty');
                        return resolve();
                    }
                    let result = [];
                    async.each(data, (value, callback) => {
                        let act = '',
                            credit = '',
                            fio = '',
                            online = '',
                            status = '';
                        // DEPOSIT
                        const deposit = ', Б:*' + Math.floor(value.deposit) + '*';
                        // ONLINE
                        if (value.online)
                            online = ', *' + value.online + '*';
                        // FIO
                        if (value.fio)
                            fio = ', Ф:*' + value.fio + '*';
                        // Credit
                        if (value.credit !== 0 && value.credit !== 0.00)
                            credit = ', Кр:*' + value.credit + '*';
                        // Status
                        if (value.status !== 'norm')
                            status = ', С:*' + value.status + '*';
                        // ACT stop date
                        if (value.status === 'norm' && value.online === 'OFF' && value.acctstoptime)
                            act = ', ' + dateFormat(value.acctstoptime, "d/m/yy HH:MM");

                        // Compile
                        result.push('U:*' + value.uid + '*, Л:*' + value.user + '*' + fio + deposit + credit + status + online + act);
                        callback();
                    }, () => {
                        debug('fetchHouseUsers:GOOD');
                        resolve(_.join(result, '\n-----------------------------------------\n'));
                    });
                }).catch(err => {
                    debug('fetchHouseUsers:ERROR ' + err);
                    reject(err);
                });
        });
    },

    /**
     * Action User Balance
     * @param {Array} args - Arguments
     * @return {Promise}
     */
    ActionUserBalance: function (args) {
        return new Promise((resolve, reject) => {
            const users = "SELECT user,deposit,credit,NULL AS status,`packets`.`packet`,`packets`.`fixed`,`packets`.`fixed_cost` FROM `users` left join `packets` on(`users`.`gid` = `packets`.`gid`) WHERE `uid`=" + args[0],
                users_block = "SELECT user,deposit,credit,'otkl' as status,`packets`.`packet`,`packets`.`fixed`,`packets`.`fixed_cost` FROM `usersblok` left join `packets` on(`usersblok`.`gid` = `packets`.`gid`) WHERE `uid`=" + args[0],
                users_del = "SELECT user,deposit,credit,'del' as status,`packets`.`packet`,`packets`.`fixed`,`packets`.`fixed_cost` FROM `usersdel` left join `packets` on(`usersdel`.`gid` = `packets`.`gid`) WHERE `uid`=" + args[0];
            db.query(users + ' UNION ' + users_block + ' UNION ' + users_del)
                .then(data => {
                    if (_.isEmpty(data)) {
                        debug('ActionUserBalance:isEmpty');
                        return resolve();
                    }

                    // PARAMS
                    let CMD = args[2],
                        SUM = args[1],
                        UID = args[0],
                        balance_after = '',
                        credit_after = '',
                        status = '',
                        sum_after;
                    const user = data[0],
                        deposit = Math.floor(user.deposit),
                        credit = Math.floor(user.credit);

                    // STATUS
                    if (user.status) {
                        const text = user.status === 'otkl' ? 'Отключен' : 'Удален';
                        status = 'Статус: *' + text + '*\n';
                    }

                    // Payment or pull balance
                    if (CMD === 'payment' || CMD === 'pull') {
                        // Payment
                        if (CMD === 'payment')
                            sum_after = parseInt(deposit) + parseInt(SUM);
                        else sum_after = parseInt(deposit) - parseInt(SUM);

                        balance_after = '\nБаланс после: *' + sum_after + '* руб';
                    } else {
                        // Credit
                        if (CMD === 'credit_auto') {
                            // Нужно подсчитать автоматически кредитную сумму
                            // Выводим типы тарифов
                            const fxd = user.fixed;
                            // Тариф без снятия, выкидываем отказ
                            if (fxd === 0)
                                return reject();

                            // Тарифы с посуточной оплатой
                            if (fxd === 1 || fxd === 7 || fxd === 10) SUM = Math.floor(user.fixed_cost * 30);
                            // Тарифы с месячной оплатой
                            if (fxd === 8 || fxd === 9 || fxd === 11) SUM = Math.floor(user.fixed_cost);
                        }

                        // Credit Disable User
                        if (CMD === 'credit_off') {
                            SUM = 'off';
                            credit_after = '\nКредит после: *0* руб';
                        } else credit_after = '\nКредит после: *' + SUM + '* руб';
                        // Edit command to credit
                        CMD = 'credit';
                    }

                    // RESULT COMPILE
                    const result = status + 'UID: *' + UID + '*\nЛогин: *' + user.user + '*\nТариф: *' + user.packet + '*\nБаланс: *' + deposit + '* руб\nКредит: *' + credit + '* руб' + balance_after + credit_after;

                    // Buttons
                    const array = [
                        {
                            text: 'Выполнить',
                            callback_data: CMD + ' ' + UID + ' ' + SUM
                        }, {
                            text: 'Отменить',
                            callback_data: 'cancel'
                        }
                    ];

                    // Return
                    debug('ActionUserBalance:GOOD');
                    return resolve({
                        result: result,
                        buttons: array
                    });
                }).catch(err => {
                    debug('ActionUserBalance:ERROR ' + err);
                    return reject(err);
                });
        });
    },

    /**
     * Fetch User
     * @param args - Arguments
     * @return {Promise}
     */
    fetchUser: function (args) {
        return new Promise((resolve, reject) => {
            const search_fio = '%' + args + '%',
                users = "SELECT `users`.`uid`,`users`.`user`,`users`.`password`,`users`.`deposit`,`users`.`credit`,`users`.`local_ip`,NULL AS status,`users`.`fio`,`packets`.`packet`, if(`inetonline`.`uid`,'ON','OFF') AS `online`, if(`inetonline`.`uid`,NULL,(SELECT `acctstoptime` FROM `radacct` WHERE `radacct`.`uid` = `users`.`uid` ORDER BY `radacctid` DESC LIMIT 1)) AS `acctstoptime`, (SELECT `lane` FROM `lanes` WHERE `lanes`.`laneid` = `lanes_houses`.`laneid`) AS `lane`,`lanes_houses`.`house`, `users`.`app` FROM `users` left join `inetonline` on(`users`.`uid` = `inetonline`.`uid`) left join `packets` on(`users`.`gid` = `packets`.`gid`) left join `lanes_houses` on(`users`.`houseid` = `lanes_houses`.`houseid`) WHERE `users`.`uid`='" + args + "' OR `users`.`user` LIKE '" + args + "' OR `users`.`fio` LIKE '" + fio + "' LIMIT 1",
                users_block = "SELECT uid,user,password,deposit,credit,local_ip,'otkl' as status,fio,`packets`.`packet`,'OFF' AS `online`,NULL AS `acctstoptime`, (SELECT `lane` FROM `lanes` WHERE `lanes`.`laneid` = `lanes_houses`.`laneid`) AS `lane`,`lanes_houses`.`house`, app FROM `usersblok` left join `packets` on(`usersblok`.`gid` = `packets`.`gid`) left join `lanes_houses` on(`usersblok`.`houseid` = `lanes_houses`.`houseid`) WHERE `uid`='" + args + "' OR `user` LIKE '" + args + "' OR `fio` LIKE '" + search_fio + "' LIMIT 1",
                users_del = "SELECT uid,user,password,deposit,credit,local_ip,'del' as status,fio,`packets`.`packet`,'OFF' AS `online`,NULL AS `acctstoptime`, (SELECT `lane` FROM `lanes` WHERE `lanes`.`laneid` = `lanes_houses`.`laneid`) AS `lane`,`lanes_houses`.`house`, app FROM `usersdel` left join `packets` on(`usersdel`.`gid` = `packets`.`gid`) left join `lanes_houses` on(`usersdel`.`houseid` = `lanes_houses`.`houseid`) WHERE `uid`='" + args + "' OR `user` LIKE '" + args + "' OR `fio` LIKE '" + search_fio + "' LIMIT 1";
            db.query(users + ' UNION ' + users_block + ' UNION ' + users_del)
                .then(data => {
                    if (_.isEmpty(data)) {
                        debug('fetchUser:isEmpty');
                        return resolve();
                    }

                    // Params
                    const user = data[0],
                        deposit = Math.floor(user.deposit),
                        credit = Math.floor(user.credit);
                    let connect = '',
                        house = '\nАдрес: *' + user.lane + ' ' + user.house + '*',
                        online = 'ДА',
                        status = '',
                        fio = '';

                    // STATUS
                    if (user.status) {
                        const text = user.status === 'otkl' ? 'Отключен' : 'Удален';
                        status = 'Статус: *' + text + '*\n';
                    }

                    // FIO
                    if (user.fio)
                        fio = '\nФИО: *' + user.fio + '*';

                    // ADDRESS
                    if (user.app)
                        house = '\nАдрес: *' + user.lane + ' ' + user.house + '/' + user.app + '*';

                    // ONLINE
                    if (user.online === 'OFF' && user.acctstoptime) {
                        const date = dateFormat(user.acctstoptime, "d/m/yy HH:MM");
                        connect = '\nКоннект: *' + date + '*';
                        online = 'НЕТ';
                    }

                    // Result
                    debug('fetchUser:GOOD');
                    const result = 'UID: *' + user.uid + '*\n' + status + 'Логин: *' + user.user + '*\nПароль: *' + user.password + '*' + fio + house + '\n\nТариф: *' + user.packet + '*\nБаланс: *' + deposit + '* руб\nКредит: *' + credit + '* руб\n\nОнлайн: *' + online + '*' + connect + '\nIP адрес: *' + user.local_ip + '*';
                    return resolve({
                        result: result,
                        buttons: []
                    });
                }).catch(err => {
                    debug('fetchUser:ERROR ' + err);
                    return reject(err);
                });
        });
    }
};
