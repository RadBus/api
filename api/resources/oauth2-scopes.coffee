http = require '../../lib/http'
Q = require 'q'

exports.register = (server, baseRoute) ->
  http.get server, "#{baseRoute}/oauth2-scopes", get

get = ->
  Q process.env.RADBUS_GOOGLE_API_AUTH_SCOPES
