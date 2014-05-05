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
          next err

# wire up server object's HTTP GET verb to an action
exports.get = (server, route, action) ->
  server.get route, createHandler(action)

# TODO: add remaining verb functions as needed (ex: post, put, delete)
