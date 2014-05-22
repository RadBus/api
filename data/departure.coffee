nextrip = require './nextrip'
moment = require 'moment-timezone'

exports.fetch = (routeId, directionId, stopId) ->
  nextrip.callApi("/#{routeId}/#{directionId}/#{stopId}")
    .then (result) ->
      for item in result.json
        time: moment(item.DepartureTime).tz(process.env.RADBUS_TIMEZONE)
        routeId: item.Route
        terminal: if item.Terminal
          item.Terminal
        gate: if item.Gate
          item.Gate
        location:
          if item.VehicleLatitude isnt 0 and item.VehicleLongitude isnt 0
            lat: item.VehicleLatitude
            long: item.VehicleLongitude
