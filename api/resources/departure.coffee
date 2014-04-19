moment = require 'moment-timezone'

exports.register = (server, baseRoute) ->
  server.get "#{baseRoute}/departures", get
  server.get "#{baseRoute}/departures/:routeFilter", get

get = (req, res, next) ->
  now = moment()

  departures270 =
    for index in [0..4]
      time: moment(now).add('minutes', (index * 5))
      route:
        number: 270
        terminal: 'C'
      stop:
        id: 'MPWD'
        name: 'Maplewood Mall Transit Center'

  departures264 =
    for index in [0..2]
      time: moment(now).add('minutes', (index * 10))
      route:
        number: 264
        terminal: if index % 2 then 'A'
      stop:
        id: 'CCPR'
        name: 'I-35W and County Rd C Park & Ride'

  departures = departures270.concat departures264

  routeFilter = req.params.routeFilter
  if routeFilter
    departures = departures.filter (d) ->
      d.route.number.toString() is routeFilter

  departures.sort (a, b) ->
    if a.time.isAfter(b.time) then 1 else -1

  res.send departures
  next()
