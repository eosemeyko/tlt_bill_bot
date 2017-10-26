const _ = require('lodash'),
    debug = require('debug')('tltbill_bot:query');

// Middleware
const checkUser = require('./middleware/checkUser');
// Models
const events = require('./models/events');

/**
 * Callback query
 * @param bot
 */
module.exports = (bot) => {
    bot.on('callback_query', (data) => {
        debug(data);

        // Стартовые опции
        const msg = data.message,
            chatId = msg.chat.id,
            editMsgID = {
                chat_id: chatId,
                message_id: msg.message_id
            };

        // Unknown USER
        if (!checkUser(chatId))
            return bot.sendMessage(chatId, 'С постороними не разговариваю!');

        // Разбираем аргументы
        let arg = data.data.split(' ');
        debug('event: ' + arg[0]);

        // Отмена действия (Очистка сообщения)
        if (arg[0] === 'cancel')
            return bot.editMessageText('Отмена действия', editMsgID);

        // Если такого события не найдено отвечаем
        if (!events[arg[0]])
            return bot.editMessageText('Извини незнаю такого!', editMsgID);

        // Запоминаем событие
        const event = events[arg[0]],
            req = event.next.req;

        // Удаляем наименование события из аргументов
        delete arg[0];
        arg = _.compact(arg);
        debug('arguments: ' + arg);

        // Проверяем количество аргументов
        if (arg.length < event.args || 0)
            return bot.editMessageText('Что-то не так!', editMsgID);

        // Если нет дальнейших действий стопим
        if (!event.next) return;

        // Если нет запроса стопим или выводим ошибку
        if (!req)
            return bot.editMessageText('Непойму что делать дальше!', editMsgID);

        // Если это последний запрос пишем и отвечаем конечным результатом
        if (event.next.end)
            return req(arg, chatId)
                .then(data => {
                    if (_.isEmpty(data))
                        return bot.editMessageText('Пустой ответ', editMsgID);

                    // Отправляет ответ в режиме Markdown text
                    editMsgID.parse_mode = "Markdown";
                    return bot.editMessageText(data, editMsgID);
                }).catch(err => {
                    if (err) console.log(err);
                    return bot.editMessageText('Ошибка запроса', editMsgID);
                });

        // Выполняем запрос c кнопками для ответа
        req(arg, chatId)
            .then(data => {
                if (_.isEmpty(data))
                    return bot.editMessageText('Пустой ответ', editMsgID);

                // Ответ с кнопками действий
                editMsgID.reply_markup = {
                    inline_keyboard: _.chunk(data)
                };
                bot.editMessageText(event.next.text, editMsgID);
            }).catch(err => {
                if (err) console.log(err);

                bot.editMessageText('Ошибка запроса', editMsgID);
            });
    });
};