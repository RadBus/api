http = require '../../lib/http'
schedule = require '../../data/schedule'

exports.register = (server, baseRoute) ->
  http.get server, "#{baseRoute}/schedule", get

get = ->
  # TODO: get from Google API profile call
  googleId = 'foo'

  schedule.fetch(googleId)
    .then (schedule) ->
      userDisplayName: 'Joe User'
      routes:
        if schedule is null then []
        else
          for route in schedule.routes
            id: route.id
            # TODO: get actual route description
            description: '(route description)'
            am:
              direction:
                id: route.am.direction
                # TODO: get actual direction description
                description: '(direction description)'
              stops:
                for stop in route.am.stops
                  id: stop
                  # TODO: get actual stop description
                  description: '(stop description)'
            pm:
              direction:
                id: route.pm.direction
                # TODO: get actual direction description
                name: '(direction description)'
              stops:
                for stop in route.pm.stops
                  id: stop
                  # TODO: get actual stop description
                  description: '(stop description)'
