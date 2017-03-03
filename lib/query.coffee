_ = require 'lodash'
debug = require('debug')('tltbill_bot:callback_query')
checkUser = require './middleware/CheckUser'
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

    # Если нет такого события
    if !events[msg.text]
      return listen.editMessageText('Извини незнаю такого!', editMsgID)

    # Запоминаем событие
    event = events[msg.text]
    # Разбираем аргументы
    arg = data.data.split(' ')

    # Проверяем количество аргументов
    if arg.length < event.args
      return listen.editMessageText('Что-то не так!', editMsgID)

    # Если такого события не найдено отвечаем
    if event.data != arg[0]
      return listen.editMessageText('Что-то пошло не так!', editMsgID)
    # Удаляем наименование события из аргументов
    delete arg[0]

    # Если нет следующего запроса стопим
    if !event.next
      return

    # Если нет запроса стопим или выводим ошибку
    if !event.next.req
      return listen.editMessageText('Непойму что делать дальше!)', editMsgID)

    # Если это последний запрос пишем и отвечаем конечным результатом
    if event.next.end
      return info[event.next.req](_.compact(arg),msg.chat.id)
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
    info[event.next.req](_.compact(arg),msg.chat.id)
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