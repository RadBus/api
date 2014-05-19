restify = require 'restify'

# examines the specified inner error and creates a wrapper error if inner
# should not be exposed in the HTTP response
exports.wrapInternal = (req, inner) ->
  if not inner or not inner.statusCode
    requestId = req.header('X-Request-ID') ? '[none]'
    error = new restify.InternalError "Something got borked! ID: #{requestId}"
    error.requestId = requestId
    error.inner = inner ?
      new Error("An undefined error was returned by an API action!")

    error
  else
    inner
