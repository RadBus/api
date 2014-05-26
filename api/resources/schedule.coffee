_ = require 'lodash'
Q = require 'q'
restify = require 'restify'
http = require '../../lib/http'
scheduleData = require '../../data/schedule'
routeData = require '../../data/route'
userData = require '../../data/user'

exports.register = (server, baseRoute) ->
  http.get server, "#{baseRoute}/schedule", fetch

fetch = (req) ->
  authToken = req.header 'Authorization'
  if not authToken
    Q new restify.InvalidCredentialsError "Missing Authorization header."

  else
    userData.fetch(authToken)
      .then (user) ->
        if not user
          new restify.InvalidCredentialsError(
            "Authorization token is invalid or expired.")

        else
          scheduleData.fetch(user.id)
            .then (data) ->
              schedule =
                user_display_name: user.displayName

              if data is null
                schedule.routes = []
                schedule

              else
                # fetch route details so we have
                # route/direction/stop descriptions
                routePromises = for route in data.routes
                  routeData.fetchDetail route.id

                Q.all(routePromises)
                  .then (routeDetails) ->
                    # build schedule routes with descriptions from route details
                    schedule.routes =
                      for route, i in data.routes
                        # results of Q.all are in same order as promised
                        routeDetail = routeDetails[i]
                        amDirection = _.find routeDetail?.directions,
                          (direction) ->
                            direction.id is route.am.direction
                        pmDirection = _.find routeDetail?.directions,
                          (direction) ->
                            direction.id is route.pm.direction

                        id: route.id
                        description: routeDetail?.description
                        am:
                          direction:
                            id: route.am.direction
                            description: amDirection?.description
                          stops:
                            for stopId in route.am.stops
                              stopDetail = _.find amDirection?.stops,
                                (stopDetail) ->
                                  stopDetail.id is stopId

                              id: stopId
                              description: stopDetail?.description
                        pm:
                          direction:
                            id: route.pm.direction
                            description: pmDirection?.description
                          stops:
                            for stopId in route.pm.stops
                              stopDetail = _.find pmDirection?.stops,
                                (stopDetail) ->
                                  stopDetail.id is stopId

                              id: stopId
                              description: stopDetail?.description

                    # detect if there was missing data
                    missingData = false
                    describeMissing = (thing) -> "(unknown #{thing})"

                    for route in schedule.routes
                      if not route.description?
                        route.description = describeMissing 'route'
                        missingData = true
                      checkTime = (time) ->
                        if not time.direction.description?
                          time.direction.description =
                            describeMissing 'direction'
                          missingData = true
                        for stop in time.stops
                          if not stop.description?
                            stop.description = describeMissing 'stop'
                            missingData = true
                      checkTime route.am
                      checkTime route.pm

                    if missingData
                      schedule.missing_data = true

                    schedule
