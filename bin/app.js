#!/usr/bin/env node
// Ensure that config directory's environment variable was specified.
// That needed when process.cwd is not a root project directory
process.env.NODE_CONFIG_DIR = process.env.NODE_CONFIG_DIR || __dirname + '/../config';

const config = require('config'),
    debug = require('debug'),
    TelegramBot = require('node-telegram-bot-api');

// Events
const events = require('../src/listen'),
    buttons = require('../src/query');

/**
 * Send debug logs to stdout (not stderr) via console.log
 */
debug.log = console.log.bind(console);

// INIT Telegram Bot
const bot = new TelegramBot(config.token, {polling: true});

// Listen Events
events(bot);
// Listen Callback buttons
buttons(bot);