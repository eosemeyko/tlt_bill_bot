_ = require 'lodash'
debug = require('debug')('tltbill_bot:query')
checkUser = require './middleware/checkUser'
events = require './models/events'

module.exports = (listen) ->
  listen.on 'callback_query', (data) ->
    debug data

    # Стартовые опции
    msg = data.message
    editMsgID =
      chat_id: msg.chat.id
      message_id: msg.message_id

    # Если вдруг Канал|Юзер неизвестный стопим
    if !checkUser msg.chat.id
      return

    # Разбираем аргументы
    arg = data.data.split(' ')
    debug 'event: ' +arg[0]

    # Отмена действия (Очистка сообщения)
    if arg[0] == 'cancel'
      return listen.editMessageText('Отмена действия', editMsgID)

    # Если такого события не найдено отвечаем
    if !events[arg[0]]
      return listen.editMessageText('Извини незнаю такого!', editMsgID)

    # Запоминаем событие
    event = events[arg[0]]
    req = event.next.req

    # Удаляем наименование события из аргументов
    delete arg[0]
    arg = _.compact(arg)
    debug 'arguments: ' +arg

    # Проверяем количество аргументов
    if arg.length < event.args || 0
      return listen.editMessageText('Что-то не так!', editMsgID)

    # Если нет дальнейших действий стопим
    if !event.next
      return

    # Если нет запроса стопим или выводим ошибку
    if !req
      return listen.editMessageText('Непойму что делать дальше!', editMsgID)

    # Если это последний запрос пишем и отвечаем конечным результатом
    if event.next.end
      return req(arg,msg.chat.id)
        .then (data) ->
          if _.isEmpty(data)
            return listen.editMessageText('Пустой ответ', editMsgID)

          # Отправляет ответ в режиме Markdown text
          editMsgID.parse_mode = "Markdown"
          listen.editMessageText(data, editMsgID)

        .catch (err) ->
          if err
            console.log err
          listen.editMessageText('Ошибка запроса', editMsgID)

    # Выполняем запрос c кнопками для ответа
    req(arg,msg.chat.id)
      .then (data) ->
        if _.isEmpty(data)
          return listen.editMessageText('Пустой ответ', editMsgID)

        # Send Callback Edit Message
        editMsgID.reply_markup =
          inline_keyboard: _.chunk(data)
        listen.editMessageText(event.next.text, editMsgID)

      .catch (err) ->
        if err
          console.log err
        listen.editMessageText('Ошибка запроса', editMsgID)

    return
  return