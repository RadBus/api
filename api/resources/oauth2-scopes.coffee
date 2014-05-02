exports.register = (server, baseRoute) ->
  server.get "#{baseRoute}/oauth2-scopes", get

get = (req, res, next) ->
  res.send process.env.RADBUS_GOOGLE_API_AUTH_SCOPES
  next()
