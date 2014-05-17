restify = require 'restify'

# create handler function use by Restify for registering a route
# - action: function that takes Restify params (req, res) and returns a promise
createHandler = (action) ->
  (req, res, next) ->
    action req, res
      .then (
        # when the promise is resolved, Restify's res.send() is called with the promise value
        (val) ->
          res.send val
          next()),
        # when the promise is rejected, Restify's next() callack is invoked with the error
        (err) ->
          next exports.internalError req, err

# wire up server object's HTTP GET verb to an action
exports.get = (server, route, action) ->
  server.get route, createHandler(action)

# TODO: add remaining verb functions as needed (ex: post, put, delete)

# examines the specified inner error and creates a wrapper error if inner
# should not be exposed in the HTTP response
exports.internalError = (req, inner) ->
  if not inner or not inner.statusCode
    requestId = req.header('X-Request-ID') ? '[none]'
    error = new restify.InternalError "Something got borked! ID: #{requestId}"
    error.requestId = requestId
    error.inner = inner ? new Error("An undefined error was returned by an API action!")

    error
  else
    inner
