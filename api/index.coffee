restify = require 'restify'

BASE_ROUTE = '/v1'

exports.register = (server) ->

  # redirect site root to API Documentation site
  server.get '/', (req, res, next) ->
    res.header 'Location', "http://dev.radbus.io"
    res.send 302
    next()

  require('./resources/root').register server, BASE_ROUTE
  require('./resources/oauth2').register server, BASE_ROUTE
  require('./resources/route').register server, BASE_ROUTE
  require('./resources/schedule').register server, BASE_ROUTE
  require('./resources/departure').register server, BASE_ROUTE
