restify = require 'restify'

exports.register = (server) ->
  # redirect site root to API Documentation site
  server.get '/', (req, res, next) ->
    res.header 'Location', "http://dev.radbus.io"
    res.send 302
    next()

  # static content
  server.get /^\/.+$/, restify.serveStatic(directory: 'web/static')
