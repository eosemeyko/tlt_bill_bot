var config = require('config'),
    debug = require('debug'),
    TelegramBot = require('node-telegram-bot-api');

/**
 * Send debug logs to stdout (not stderr) via console.log
 */
debug.log = console.log.bind(console);

// INIT Telegram Bot
var bot = new TelegramBot(config.token, { polling: true });

// EVENTS
var listen_events = require('../src/listen');

// Listen Events
listen_events(bot);