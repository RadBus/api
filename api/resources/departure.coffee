Q = require 'q'
restify = require 'restify'
moment = require 'moment-timezone'
_ = require 'lodash'
helpers = require './helpers'
http = require '../../lib/http'
security = require '../../lib/security'
scheduleData = require '../../data/schedule'
routeData = require '../../data/route'
departureData = require '../../data/departure'

exports.register = (server, baseRoute) ->
  http.get server, "#{baseRoute}/departures", (req) ->
    security.getUser(req)
      .then fetch

fetch = (user) ->
  # determine if it's AM or PM
  now = moment()
  noon = moment(now).tz(process.env.RADBUS_TIMEZONE)
    .startOf('day')
    .add 'hours', 12
  isMorning = now.isBefore noon

  # determine how far into the future to return departures
  cutOff = moment(now).add 'minutes',
    parseInt(process.env.RADBUS_FUTURE_MINUTES)

  # fetch the user's schedule and get departure data
  scheduleData.fetch(user.id)
    .then (schedule) ->

      # build array of inputs for departure queries
      departureInputs = []
      for route in schedule.routes
        section = if isMorning then route.am else route.pm
        for stop in section.stops
          input =
            routeId: route.id
            directionId: section.direction
            stopId: stop

          departureInputs.push input

      # get departures
      departurePromises = for input in departureInputs
        departureData.fetch input.routeId, input.directionId, input.stopId

      # get route details (for stop descriptions)
      routeDetailPromises = for route in schedule.routes
        routeData.fetchDetail route.id

      # wait for all departures and route details to come back
      Q.spread [Q.all(departurePromises), Q.all(routeDetailPromises)],
        (departureResults, routeDetailResults) ->

          getStopDescription = (routeId, directionId, stopId) ->
            route = _.find routeDetailResults,
              id: routeId
            direction = _.find route.directions,
              id: directionId
            stop = _.find direction.stops,
              id: stopId

            stop.description

          # build final response
          departureDetails = []

          for result, i in departureResults
            # get corresponding input
            input = departureInputs[i]

            for departure in result
              # filter out departures too far into the future
              if not departure.time.isAfter(cutOff)
                departureDetail =
                  time: departure.time
                  route:
                    id: departure.routeId
                    terminal: departure.terminal
                  stop:
                    id: input.stopId
                    description:
                      getStopDescription departure.routeId,
                        input.directionId,
                        input.stopId
                    gate: departure.gate
                  location: departure.location

                departureDetails.push departureDetail

          # return list, sorted by departure time
          departureDetails.sort (a, b) ->
            if a.time.isAfter(b.time) then 1 else -1
