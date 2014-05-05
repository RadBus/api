http = require '../../lib/http'
nextrip = require '../../data/nextrip'

exports.register = (server, baseRoute) ->
  http.get server, "#{baseRoute}/routes", nextrip.fetchAllRoutes
  http.get server, "#{baseRoute}/routes/:routeId", getRouteDetail

getRouteDetail = (req, res) ->
  nextrip.fetchRouteDetail req.params.routeId
