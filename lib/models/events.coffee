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

  # Payment Balance User
  payment:
    args: 2
    next:
      req: actions.PaymentUserBalance
      end: true

  # Pull Balance User
  pull:
    args: 2
    next:
      req: actions.PullUserBalance
      end: true