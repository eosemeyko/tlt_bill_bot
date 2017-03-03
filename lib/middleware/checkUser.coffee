config = require 'config'
users = config.users

###
# Check UserID|ChatID Access
# @param UserID
# @returns {Boolean}
###
module.exports = (UserID) ->
  if users[UserID]
    return true
  return false