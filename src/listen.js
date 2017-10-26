const _ = require('lodash'),
    debug = require('debug')('tltbill_bot:listen');

// Middleware
const checkUser = require('./middleware/checkUser');
// Models
const info = require('./models/information');

/**
 * Bot Event LISTEN
 * @param bot
 */
module.exports = (bot) => {
    /**
     * Список доступных комманд
     */
    bot.onText(/^\/start/, (msg) => {
        const chatId = msg.chat.id;
        if (!checkUser(chatId))
            return bot.sendMessage(chatId, 'С постороними не разговариваю!');

        const data = ['/поиск'];

        bot.sendMessage(chatId, 'Приветствую!', {
            reply_markup: {
                keyboard: _.chunk(data),
                one_time_keyboard: true
            }
        });
    });

    /**
     * Поиск пользователей по улица/дом
     */
    bot.onText(/^\/по/, (msg) => {
        const chatId = msg.chat.id;
        if (!checkUser(chatId))
            return bot.sendMessage(chatId, 'С постороними не разговариваю!');

        // Get Lines
        GetInfo(bot, chatId, 'fetchLanes', 'Выберите улицу');
    });

    /**
     * Пополнение баланса пользователя [UID, sum]
     */
    bot.onText(/\/оп (.+)/, (msg, match) => {
        const chatId = msg.chat.id;
        if (!checkUser(chatId))
            return bot.sendMessage(chatId, 'С постороними не разговариваю!');

        let args = match[1].split(' ');
        // Принимается только 2 значения
        if (args.length < 2)
            return bot.sendMessage(chatId, 'Нехватает значений!');

        // UID должен быть числом
        if (_.isNaN(Number(args[0])))
            return bot.sendMessage(chatId, 'UID: принимаю только число!');

        // Только числа
        if (_.isNaN(Number(args[1])))
            return bot.sendMessage(chatId, 'Сумма: принимаю только числа!');

        // Аргумент только положительный
        if (args[1] < 0)
            return bot.sendMessage(chatId, 'Сумма: только положительная!');

        // Добавляем действие платеж
        args[2] = 'payment';

        // Post User payment
        GetInfo(bot, chatId, 'ActionUserBalance', 'Пополнение на сумму *' + args[1] + '* р\n', args);
    });

    /**
     * Снятие с баланса пользователя  [UID, sum]
     */
    bot.onText(/\/сн (.+)/, (msg, match) => {
        const chatId = msg.chat.id;
        if (!checkUser(chatId))
            return bot.sendMessage(chatId, 'С постороними не разговариваю!');

        let args = match[1].split(' ');
        // Допускаю только 2 параметра
        if (args.length < 2)
            return bot.sendMessage(chatId, 'Нехватает значений!');

        // UID должен быть числом
        if (_.isNaN(Number(args[0])))
            return bot.sendMessage(chatId, 'UID: принимаю только число!');

        // Только числовые значения
        if (_.isNaN(Number(args[1])))
            return bot.sendMessage(chatId, 'Сумма: принимаю только числа!');

        // Только положительная сумма
        if (args[1] < 0)
            return bot.sendMessage(chatId, 'Сумма: только положительная!');

        // Push Action to arguments
        args[2] = 'pull';

        // Post pull payment to user
        GetInfo(bot, chatId, 'ActionUserBalance', 'Вычесть из баланса *' + args[1] + '* р\n', args);
    });

    /**
     * Включение/отключение кредита пользователю [UID, sum || вкл|on выкл|off]
     */
    bot.onText(/\/кр (.+)/, (msg, match) => {
        const chatId = msg.chat.id;
        if (!checkUser(chatId))
            return bot.sendMessage(chatId, 'С постороними не разговариваю!');

        let args = match[1].split(' ');
        // Допускаю только 2 аргумента
        if (args.length < 2)
            return bot.sendMessage(chatId, 'Нехватает значений!');

        // UID должен быть числом
        if (_.isNaN(Number(args[0])))
            return bot.sendMessage(chatId, 'UID: принимаю только число!');

        /**
         * Проверка второго значения
         */
        // Если не число 
        if (_.isNaN(Number(args[1]))) {
            let text = 'Активация кредита\n';
            const action = args[1];

            // Если неизвестный аргумет отвечаем
            if (action !== 'вкл' && action !== 'on' && action !== 'выкл' && action !== 'off')
                return bot.sendMessage(chatId, 'Второе значение непонятно!');

            // проверяем параметр
            if (action === 'вкл' || action === 'on')
                args[2] = 'credit_auto';

            if (action === 'выкл' || action === 'off') {
                text = 'Отключение кредита\n';
                args[2] = 'credit_off';
            }

            // Post edit credit user
            GetInfo(bot, chatId, 'ActionUserBalance', text, args);
        }

        // Если цифра = сумма кредита
        else {
            // Только положительная
            if (args[1] < 0)
                return bot.sendMessage(chatId, 'Сумма только положительная!');

            // Отправляем команду по стандарту
            args[2] = 'credit_sum';
            GetInfo(bot, chatId, 'ActionUserBalance', 'Активация кредита на сумму *' + args[1] + '* р\n', args);
        }
    });

    /**
     * Поиск пользователя [VALUE]
     */
    bot.onText(/\/юз (.+)/, (msg, match) => {
        const chatId = msg.chat.id;
        if (!checkUser(chatId))
            return bot.sendMessage(chatId, 'С постороними не разговариваю!');

        GetInfo(bot, chatId, 'fetchUser', '*Пользователь*\n', match[1]);
    });

    /**
     * Show listen message
     */
    bot.on('message', (data) => {
        debug(data);
    });
};

/**
 * Request with buttons for reply
 * @param bot
 * @param {number} chatId
 * @param {string} req - Request api model
 * @param {string} text - New Message Text
 * @param args - Arguments
 */
function GetInfo(bot, chatId, req, text, args) {
    info[req](args)
        .then(data => {
            if (_.isEmpty(data))
                return bot.sendMessage(chatId, 'Пустой ответ');

            const text2 = data.result ? data.result : '';
            const btn = data.buttons ? _.chunk(data.buttons) : null;

            // Return message
            return bot.sendMessage(chatId, text + text2, {
                reply_markup: {
                    inline_keyboard: btn
                },
                one_time_keyboard: true,
                parse_mode: "Markdown"
            });
        }).catch(err => {
            if (err) console.log(err);
            return bot.sendMessage(chatId, 'Ошибка запроса');
        });
};