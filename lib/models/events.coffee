information = require './information'
actions = require './actions'

module.exports =
  # Select lane (laneid)
  select_lane:
    args: 1
    next:
      text: 'Выберите номер дома'
      req: information.fetchHouses

  # Select home number (houseid)
  select_house:
    args: 1
    next:
      req: information.fetchHouseUsers
      end: true

  # Payment User
  payment:
    args: 2
    next:
      req: actions.PaymentUser
      end: true