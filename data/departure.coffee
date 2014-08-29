moment = require 'moment-timezone'
_ = require 'lodash'
nextrip = require './nextrip'

projectDeparture = (item) ->
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

exports.fetchByRouteDirectionAndStop = (routeId, directionId, stopId) ->
  nextrip.callApi("#{routeId}/#{directionId}/#{stopId}")
    .then (result) ->
      for item in result.json
        projectDeparture item

exports.fetchByRouteAndMtStopId = (routeId, stopId) ->
  nextrip.callApi("#{stopId}")
    .then (result) ->
      # filter out other routes
      filtered = _.filter result.json, Route: routeId
      for item in filtered
        projectDeparture item
