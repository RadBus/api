API_VERSION = '1.0.0'

exports.register = (server, baseRoute) ->
  server.get "#{baseRoute}/", (req, res, next) ->
    res.send
      service_name: server.name
      app_version: server.appVersion
      api_version: API_VERSION
    next()
