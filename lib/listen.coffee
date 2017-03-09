_ = require 'lodash'
debug = require('debug')('tltbill_bot:message')
checkUser = require './middleware/checkUser'
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

      bot.sendMessage chatId, 'Приветствую!', reply_markup:
        keyboard: _.chunk(data)
        one_time_keyboard: true
    return

  # Search Users the Home
  bot.onText /^\/по/, (msg) ->
    chatId = msg.chat.id

    if checkUser chatId
      GetInfo bot, chatId, 'fetchLanes', 'Выберите улицу'
    return

  # Payment User  [UID, sum]
  bot.onText /\/оп (.+)/, (msg, match) ->
    chatId = msg.chat.id

    if checkUser chatId
      args = match[1].split(' ')

      # Only two arguments
      if args.length < 2
        return bot.sendMessage chatId, 'Нехватает значений!'

      # Только числовые значения
      if _.isNaN(Number(args[0])) or _.isNaN(Number(args[1]))
        return bot.sendMessage chatId, 'Принимаю только числа!'

      # Only +
      if args[1] and args[1] < 0
        return bot.sendMessage chatId, 'Сумма только положительная!'

      GetInfo bot, chatId, 'fetchUserBalance', 'Пополнение на сумму *'+args[1]+ '*\n', args
    return

  # Show listen message
  bot.on 'message', (data) ->
    debug data
    return
  return

###
# Request with buttons for reply
# @param bot
# @param chatId
# @param {string} req - Request api model
# @param {string} text - New Message Text
# @param args - Arguments
###
GetInfo = (bot,chatId,req,text,args) ->
  info[req](args)
    .then (data) ->
      if data
        text2 = if data.result then data.result else ''
        buttons = if data.buttons then _.chunk(data.buttons) else null
        bot.sendMessage chatId, text + text2,
          reply_markup:
            inline_keyboard: buttons
            one_time_keyboard: true
          parse_mode: "Markdown"
      else bot.sendMessage chatId, 'Пустой ответ'

    .catch (err) ->
      if err
        console.log err
      bot.sendMessage chatId, 'Ошибка запроса'
  return