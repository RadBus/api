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
    .add 12, 'hours'
  isMorning = now.isBefore noon

  # determine how far into the future to return departures
  futureMinutes = parseInt(process.env.RADBUS_FUTURE_MINUTES)
  cutOff = moment(now).add futureMinutes, 'minutes'

  # fetch the user's schedule and get departure data
  scheduleData.fetch(user.id)
    .then (schedule) ->

      # build array of inputs for departure queries
      departureInputs = []
      routes = if schedule != null then schedule.routes else []
      for route in routes
        section = if isMorning then route.am else route.pm
        for stop in section.stops
          input =
            routeId: route.id
            directionId: section.direction
            stopId: stop

          departureInputs.push input

      # get departures
      departurePromises = for input in departureInputs
        mtStop = helpers.parseMetroTransitStop input.stopId
        if mtStop
          departureData.fetchByRouteAndMtStopId input.routeId, mtStop.id
        else
          departureData.fetchByRouteDirectionAndStop input.routeId, input.directionId, input.stopId

      # get route details (for stop descriptions)
      routeDetailPromises = for route in routes
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
                mtStop = helpers.parseMetroTransitStop input.stopId

                departureDetail =
                  time: departure.time
                  route:
                    id: departure.routeId
                    terminal: departure.terminal
                  stop:
                    id:
                      if mtStop
                        mtStop.id
                      else
                        input.stopId
                    description:
                      if mtStop
                        mtStop.description
                      else
                        getStopDescription departure.routeId,
                          input.directionId,
                          input.stopId
                    gate: departure.gate
                  location: departure.location

                departureDetails.push departureDetail

          # return list, sorted by departure time
          departureDetails.sort (a, b) ->
            if a.time.isAfter(b.time) then 1 else -1
