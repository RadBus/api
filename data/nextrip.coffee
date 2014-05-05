request = require 'request'
Q = require 'q'

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
