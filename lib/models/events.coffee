module.exports =
  # Select lane (laneid)
  'Выберите улицу':
    data: 'select_lane'
    args: 2
    next:
      text: 'Выберите номер дома'
      req: 'fetchHouses'

  # Select home number (houseid)
  'Выберите номер дома':
    data: 'select_house'
    args: 2
    next:
      req: 'fetchHouseUsers'
      end: true
