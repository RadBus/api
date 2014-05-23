restify = require 'restify'
http = require '../../lib/http'
routeData = require '../../data/route'

exports.register = (server, baseRoute) ->
  http.get server, "#{baseRoute}/routes", fetchAll
  http.get server, "#{baseRoute}/routes/:routeId", fetchDetail

fetchAll = ->
  routeData.fetchAll()
    .then (routes) ->
      for route in routes
        id: route.id,
        description: route.description

fetchDetail = (req) ->
  routeId = req.params.routeId

  routeData.fetchDetail(routeId)
    .then (directions) ->
      if directions.length is 0
        new restify.ResourceNotFoundError "No such route, dude!"

      else
        for direction in directions
          id: direction.id
          description: direction.description
          stops:
            for stop in direction.stops
              id: stop.id
              description: stop.description
