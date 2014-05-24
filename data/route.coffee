Q = require 'q'
nextrip = require './nextrip'

exports.fetchAll = ->
  nextrip.callApi('Routes')
    .then (result) ->
      for item in result.json
        id: item.Route,
        description: item.Description

exports.fetchDetail = (routeId) ->
  descriptionPromise =
    nextrip.callApi('Routes')
      .then (result) ->
        routesById = {}
        for item in result.json
          routesById[item.Route] = item.Description

        routesById[routeId]

  directionsPromise =
    nextrip.callApi("Directions/#{routeId}")
      .then (result) ->
        directions = for item in result.json
          direction =
            id: item.Value
            description:
              item.Text.toLowerCase().replace /^(.)/, ($1) -> $1.toUpperCase()

          nextrip.callApi("Stops/#{routeId}/#{direction.id}", direction)
            .then (result) ->
              result.state.stops =
                for item in result.json
                  id: item.Value
                  description: item.Text

              result.state

        Q.all directions

  Q.spread [descriptionPromise, directionsPromise], (description, directions) ->
    if description
      id: routeId
      description: description
      directions: directions
