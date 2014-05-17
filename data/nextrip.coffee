request = require 'request'
Q = require 'q'
moment = require 'moment-timezone'

callApi = (url, state) ->
  options =
    url: "http://svc.metrotransit.org/NexTrip/#{url}"
    json: true

  d = Q.defer()
  request.get options, (err, response, body) ->
    if err
      d.reject err
    else
      d.resolve
        json: body
        state: state
  d.promise

exports.fetchAllRoutes = ->
  callApi 'Routes'
    .then (result) ->
      for item in result.json
        id: item.Route,
        description: item.Description

exports.fetchRouteDetail = (routeId) ->
  callApi "Directions/#{routeId}"
    .then (result) ->
      directions = for item in result.json
        direction =
          id: item.Value
          description: item.Text.toLowerCase().replace /^(.)/, ($1) -> $1.toUpperCase()

        callApi "Stops/#{routeId}/#{direction.id}", direction
          .then (result) ->
            result.state.stops =
              for item in result.json
                id: item.Value
                description: item.Text

            result.state

      Q.all directions

exports.fetchDetapartures = (routeId, directionId, stopId) ->
  callApi "/#{routeId}/#{directionId}/#{stopId}"
    .then (result) ->
      for item in result.json
        time: moment(item.DepartureTime).tz(process.env.RADBUS_TIMEZONE)
        routeId: item.Route
        terminal: if item.Terminal
          item.Terminal
        gate: if item.Gate
          item.Gate
        location: if item.VehicleLatitude isnt 0 and item.VehicleLongitude isnt 0
          lat: item.VehicleLatitude
          long: item.VehicleLongitude
