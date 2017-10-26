const information = require('./information'),
    actions = require('./actions');

module.exports = {
    // Выбрана улица, требуем выбрать дом
    select_lane: {
        args: 1,
        next: {
            text: 'Выберите номер дома',
            req: information.fetchHouses
        }
    },

    // Выбран дом - выводим пользователей
    select_house: {
        args: 1,
        next: {
            req: information.fetchHouseUsers,
            end: true
        }
    },

    // Пополнение баланса
    payment: {
        args: 2,
        next: {
            req: actions.PaymentUserBalance,
            end: true
        }
    },

    // Снятие с баланса
    pull: {
        args: 2,
        next: {
            req: actions.PullUserBalance,
            end: true
        }
    },

    // Вкл/Откл Кредита
    credit: {
        args: 2,
        next: {
            req: actions.CreditUser,
            end: true
        }
    }
};