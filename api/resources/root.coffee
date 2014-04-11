thisPackage = require '../../package'

appName = ''

exports.register = (server) ->
  appName = server.name
  server.get '/', get

get = (req, res, next) ->
  message = "#{appName} API, version #{thisPackage.version}"
  res.send message
  next()
