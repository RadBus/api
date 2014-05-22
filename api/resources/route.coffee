http = require '../../lib/http'
routeData = require '../../data/route'

exports.register = (server, baseRoute) ->
  http.get server, "#{baseRoute}/routes", routeData.fetchAll
  http.get server, "#{baseRoute}/routes/:routeId", (req, res) ->
    routeData.fetchDetail req.params.routeId
