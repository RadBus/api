restify = require 'restify'
thisPackage = require './package'

# configure server
server = restify.createServer
  name: thisPackage.description

server.use restify.gzipResponse()
server.use restify.bodyParser()
server.use restify.queryParser
  mapParams: false

# CORS support
server.use restify.CORS()
server.on 'MethodNotAllowed', (req, res, next) ->
  if req.method.toUpperCase() is 'OPTIONS'
    allowHeaders = ['Accept', 'Accept-Version', 'Content-Type', 'Authorization'];
    allowMethods = ['GET', 'OPTIONS', 'POST']

    for method in allowMethods
      if res.methods.indexOf(method) is -1
        res.methods.push(method);

    res.header 'Access-Control-Allow-Credentials', true
    res.header 'Access-Control-Allow-Headers', allowHeaders.join(', ')
    res.header 'Access-Control-Allow-Methods', res.methods.join(', ')
    res.header 'Access-Control-Allow-Origin', req.headers.origin

    res.send 204;

  else
    res.send new restify.MethodNotAllowedError()

  next()

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
