_ = require 'lodash'
debug = require('debug')('tltbill_bot:message')
checkUser = require './middleware/CheckUser'
buttons = require './query'
info = require './models/information'

###
# Bot API LISTEN
# @param bot
###
module.exports = (bot) ->
  # INIT Callback Buttons query
  buttons bot

  # LIST Command
  bot.onText /^\/start/, (msg) ->
    chatId = msg.chat.id
    if checkUser chatId
      data =
        ['/поиск']

      bot.sendMessage chatId, 'Приветсвую!', reply_markup:
        keyboard: _.chunk(data)
        one_time_keyboard: true
    return

  # Search Users the Home
  bot.onText /^\/по/, (msg) ->
    chatId = msg.chat.id

    if checkUser chatId
      Request bot, chatId, 'fetchLanes', 'Выберите улицу'
    return

  bot.on 'message', (data) ->
    debug data
    return
  return

###
# Request Information
# @param bot
# @param chatId
# @param {string} req - Information Model
# @param {string} text - New Message Text
###
Request = (bot,chatId,req,text) ->
  info[req]()
    .then (data) ->
      if data
        bot.sendMessage chatId, text, reply_markup:
          inline_keyboard: _.chunk(data)
          one_time_keyboard: true
      else bot.sendMessage chatId, 'Пустой ответ'

    .catch (err) ->
      if err
        console.log err
      bot.sendMessage chatId, 'Ошибка запроса'
  return