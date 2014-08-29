http = require '../../lib/http'
Q = require 'q'

API_VERSION = '1.1.0'

exports.register = (server, baseRoute) ->
  http.get server, "#{baseRoute}/", -> fetch server

fetch = (server) ->
  Q
    service_name: server.name
    app_version: server.appVersion
    api_version: API_VERSION
