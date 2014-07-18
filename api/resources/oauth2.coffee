http = require '../../lib/http'
Q = require 'q'

exports.register = (server, baseRoute) ->
  http.get server, "#{baseRoute}/oauth2", get

get = ->
  Q {
    client_id: process.env.RADBUS_GOOGLE_API_CLIENT_ID
    client_secret: process.env.RADBUS_GOOGLE_API_CLIENT_SECRET
    scopes: process.env.RADBUS_GOOGLE_API_AUTH_SCOPES
  }
