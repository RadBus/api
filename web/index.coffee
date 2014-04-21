restify = require 'restify'

exports.register = (server) ->
  server.get '/js/config.js', (req, res, next) ->
    # res.contentType = 'application/javascript'
    res.contentType = 'text/plain'
    res.send "var googleClientId = '#{process.env.BUS_API_GOOGLE_API_CLIENT_ID}';\n
              var googleClientSecret = '#{process.env.BUS_API_GOOGLE_API_CLIENT_SECRET}';\n
              var googleAuthScopes = '#{process.env.BUS_API_GOOGLE_API_AUTH_SCOPES}';\n
              var googleAnalyticsId = '#{process.env.BUS_API_GOOGLE_ANALYTICS_ID}';"
    next()

  server.get /\/.*/, restify.serveStatic
    directory: './web/static',
    default: 'index.html'
