_ = require 'lodash'
debug = require('debug')('tltbill_bot:callback_query')
checkUser = require './middleware/checkUser'
events = require './models/events'
info = require './models/information'

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

    # Если такого события не найдено отвечаем
    if !events[arg[0]]
      return listen.editMessageText('Извини незнаю такого!', editMsgID)

    # Отмена действия (Очистка сообщения)
    if arg[0] == 'cancel'
      return listen.editMessageText('Отмена действия', editMsgID)

    # Запоминаем событие
    event = events[arg[0]]

    # Удаляем наименование события из аргументов
    delete arg[0]
    arg = _.compact(arg)

    # Проверяем количество аргументов
    if arg.length < event.args || 0
      return listen.editMessageText('Что-то не так!', editMsgID)

    # Если нет дальнейших действий стопим
    if !event.next
      return

    # Если нет запроса стопим или выводим ошибку
    if !event.next.req
      return listen.editMessageText('Непойму что делать дальше!', editMsgID)

    # Если это последний запрос пишем и отвечаем конечным результатом
    if event.next.end
      return info[event.next.req](arg,msg.chat.id)
        .then (data) ->
          if data
            # Отправляет ответ в режиме Markdown text
            editMsgID.parse_mode = "Markdown"
            listen.editMessageText(data, editMsgID)
          else listen.editMessageText('Пустой ответ', editMsgID)
        .catch (err) ->
          if err
            console.log err
          listen.editMessageText('Ошибка запроса', editMsgID)

    # Выполняем запрос c кнопками для ответа
    info[event.next.req](arg,msg.chat.id)
      .then (data) ->
        if data
          # Message text
          listen.editMessageText(event.next.text, editMsgID)
          # Message button
          listen.editMessageReplyMarkup({ inline_keyboard: _.chunk(data) }, editMsgID)
        else listen.editMessageText('Пустой ответ', editMsgID)

      .catch (err) ->
        if err
          console.log err
        listen.editMessageText('Ошибка запроса', editMsgID)

    return
  return