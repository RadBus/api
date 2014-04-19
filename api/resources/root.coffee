thisPackage = require '../../package'

appName = ''

exports.register = (server, baseRoute) ->
  appName = server.name
  server.get "#{baseRoute}/", get

get = (req, res, next) ->
  message = "#{appName} API, version #{thisPackage.version}"
  res.send message
  next()
