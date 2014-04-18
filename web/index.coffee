restify = require 'restify'

exports.register = (server) ->
  server.get /\/.*/, restify.serveStatic
    directory: './web/static',
    default: 'index.html'
