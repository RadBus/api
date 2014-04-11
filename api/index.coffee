restify = require 'restify'

exports.register = (server) ->
  require('./resources/root').register server
  require('./resources/departure').register server
