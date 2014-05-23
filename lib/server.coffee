restify = require 'restify'
thisPackage = require '../package'
error = require './error'

LOG_PREFIX = 'SERVER: '

# configure server
server = restify.createServer
  name: thisPackage.description

server.appVersion = thisPackage.version

# CORS support
server.pre restify.CORS()
server.on 'MethodNotAllowed', (req, res, next) ->
  if req.method.toUpperCase() is 'OPTIONS'
    allowHeaders = [
      'Accept'
      'Accept-Version'
      'Content-Type'
      'Authorization'
    ]
    allowMethods = [
      'GET'
      'OPTIONS'
      'POST'
    ]

    for method in allowMethods
      if res.methods.indexOf(method) is -1
        res.methods.push(method)

    res.header 'Access-Control-Allow-Credentials', true
    res.header 'Access-Control-Allow-Headers', allowHeaders.join(', ')
    res.header 'Access-Control-Allow-Methods', res.methods.join(', ')
    res.header 'Access-Control-Allow-Origin', req.headers.origin

    res.send 204

  else
    res.send new restify.MethodNotAllowedError()

  next()

# require HTTPS
server.use (req, res, next) ->
  hostPort = req.header('Host')
  host = /^(.+?)(:\d+)?$/.exec(hostPort)[1]
  isSecure = req.isSecure() or (req.headers['x-forwarded-proto'] is 'https')
  isLocalhost = host is 'localhost' or host is '127.0.0.1'

  if not isSecure and not isLocalhost
    res.header 'Location', "https://#{hostPort}#{req.url}"
    res.send 301
    next false

  else
    next()

server.use restify.gzipResponse()
server.use restify.bodyParser()
server.use restify.queryParser
  mapParams: false

# request audit logging
logRequest = (req, res, route, err) ->
  if err and err.inner
    console.log "#{LOG_PREFIX}REQUEST ERROR (request-id=#{err.requestId}): " +
                "#{err.inner.stack ? err.inner}"

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

  console.log "#{LOG_PREFIX}#{xForwardFor} \"#{method} #{url} " +
              "HTTP/#{httpVersion}\":#{contentType} " +
              "request-id=#{requestId} accept=#{accept} status=#{status} " +
              "#{contentType}:#{contentLength} \"#{userAgent}\""

server.on 'after', logRequest

# log uncaught exceptions
server.on 'uncaughtException', (req, res, route, err) ->
  err = error.wrapInternal req, err
  logRequest req, res, route, err

module.exports = server
