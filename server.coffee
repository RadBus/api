restify = require 'restify'
thisPackage = require './package'

# configure server
server = restify.createServer
  name: thisPackage.description

server.use restify.gzipResponse()
server.use restify.bodyParser()
server.use restify.queryParser
  mapParams: false

# request audit logging
logRequest = (req, res, route, error) ->
  xForwardFor = req.header('X-Forwarded-For') or req.connection.remoteAddress
  method = req.method
  url = req.url
  httpVersion = req.httpVersion
  contentType = req.header('Content-Type') or '-'
  requestId = req.header('X-Request-ID') or '-'
  accept = req.header('Accept') or '-'
  status = res.statusCode
  contentType = res.header('Content-Type') or '-'
  contentLength = res.header('Content-Length') or '-'
  userAgent = req.header('User-Agent') or '-'

  console.log "#{xForwardFor} \"#{method} #{url} HTTP/#{httpVersion}\":#{contentType} " +
              "request-id=#{requestId} accept=#{accept} status=#{status} " +
              "#{contentType}:#{contentLength} \"#{userAgent}\""

server.on 'after', logRequest

# log errors on the server
server.on 'uncaughtException', (req, res, route, error) ->
  requestId = req.header('X-Request-ID') or '[none]';

  console.log "ERROR (request-id=#{requestId}): #{error.stack}"
  res.send new restify.InternalError("Ah CRAP! #{requestId}")

  logRequest req, res, route, error

module.exports = server
