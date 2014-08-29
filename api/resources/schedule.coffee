_ = require 'lodash'
Q = require 'q'
restify = require 'restify'
util = require 'util'
helpers = require './helpers'
http = require '../../lib/http'
security = require '../../lib/security'
scheduleData = require '../../data/schedule'
routeData = require '../../data/route'

exports.register = (server, baseRoute) ->
  http.get server, "#{baseRoute}/schedule", (req) ->
    security.getUser(req)
      .then fetch

  http.post server, "#{baseRoute}/schedule/routes", (req) ->
    security.getUser(req)
      .then (user) ->
        userRoute =
          user: user
          route: req.body
        add userRoute

  http.delete server, "#{baseRoute}/schedule/routes/:route", (req) ->
    security.getUser(req)
      .then (user) ->
        userRouteId =
          user: user
          routeId: req.params.route
        remove userRouteId

getUserSchedule = (user) ->
  scheduleData.fetch(user.id)
    .then (schedule) ->
      user: user
      schedule: schedule

fetch = (user) ->
  getUserSchedule(user)
    .then (userSchedule) ->
      schedule =
        user_display_name: userSchedule.user.displayName

      if userSchedule.schedule is null
        schedule.routes = []
        schedule

      else
        # fetch route details so we have
        # route/direction/stop descriptions
        routePromises = for route in userSchedule.schedule.routes
          routeData.fetchDetail route.id

        Q.all(routePromises)
          .then (routeDetails) ->
            # build schedule routes with descriptions from route details
            schedule.routes =
              for route, i in userSchedule.schedule.routes
                # results of Q.all are in same order as promised
                routeDetail = routeDetails[i]
                amDirection = _.find routeDetail?.directions,
                  id: route.am.direction
                pmDirection = _.find routeDetail?.directions,
                  id: route.pm.direction

                renderTime = (time, timeDirection) ->
                  direction:
                    id: time.direction
                    description: timeDirection?.description
                  stops:
                    for stopId in time.stops
                      mtStop = helpers.parseMetroTransitStop stopId
                      if mtStop
                        mtStop
                      else
                        stopDetail = _.find timeDirection?.stops,
                          id: stopId

                        id: stopId
                        description: stopDetail?.description

                id: route.id
                description: routeDetail?.description
                am: renderTime route.am, amDirection
                pm: renderTime route.pm, pmDirection

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

add = (userRoute) ->
  route = userRoute.route

  if not route
    Q.reject new restify.InvalidContentError "Route is required"

  else
    if not route.id
      Q.reject new restify.InvalidContentError "Route ID is required"

    else
      routeData.fetchDetail(route.id)
        .then (routeDetail) ->
          if not routeDetail
            Q.reject new restify.InvalidContentError "Invalid route ID"

          else
            validateSection = (section, name) ->
              if not section
                errors.push "#{name} section is required"

              else
                if not section.direction
                  errors.push "#{name} section direction is required"

                else
                  directionDetail = _.find routeDetail.directions,
                    id: section.direction

                  if not directionDetail
                    errors.push "Invalid #{name} section " +
                      "direction: #{section.direction}"

                  else
                    stops = section.stops
                    if not stops or
                    not util.isArray(stops) or
                    not stops.length > 0
                      errors.push "#{name} section must contain " +
                        "at least one stop"

                    else
                      for stopId in stops
                        mtStop = helpers.parseMetroTransitStop stopId
                        if not mtStop
                          stopDetail = _.find directionDetail.stops,
                            id: stopId

                          if not stopDetail
                            errors.push "Invalid #{name} section stop: #{stopId}"

            errors = []
            validateSection route.am, 'AM'
            validateSection route.pm, 'PM'

            if errors.length > 0
              Q.reject new restify.InvalidContentError(errors.join('; '))

            else
              getUserSchedule(userRoute.user)
                .then (userSchedule) ->
                  schedule =
                    if userSchedule.schedule
                      userSchedule.schedule.toObject()
                    else
                      userId: userSchedule.user.id
                      routes: []

                  delete schedule._id

                  existingRouteIndex = _.findIndex schedule.routes,
                    id: route.id

                  statusCode =
                    if existingRouteIndex is -1
                      schedule.routes.push route
                      201
                    else
                      schedule.routes[existingRouteIndex] = route
                      204

                  scheduleData.upsert(schedule)
                    .then ->
                      statusCode

remove = (userRouteId) ->
  getUserSchedule(userRouteId.user)
    .then (userSchedule) ->
      if not userSchedule.schedule
        Q.reject new restify.InvalidContentError(
          "User does not yet have a schedule")

      else
        schedule = userSchedule.schedule.toObject()
        delete schedule._id

        existingRouteIndex = _.findIndex schedule.routes,
          id: userRouteId.routeId

        if existingRouteIndex is -1
          Q.reject new restify.InvalidContentError(
            "Schedule does not contain route #{userRouteId.routeId}")

        else
          schedule.routes.splice existingRouteIndex, 1

          scheduleData.upsert(schedule)
            .then ->
              204
