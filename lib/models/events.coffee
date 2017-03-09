module.exports =
  # Select lane (laneid)
  select_lane:
    args: 1
    next:
      text: 'Выберите номер дома'
      req: 'fetchHouses'

  # Select home number (houseid)
  select_house:
    args: 1
    next:
      req: 'fetchHouseUsers'
      end: true