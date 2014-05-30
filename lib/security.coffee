Q = require 'q'
restify = require 'restify'
userData = require '../data/user'

# gets the current user and user's schedule if the user is authenticated
# otherwise returns the appropriate restify error if they are not
exports.getUser = (req) ->
  authToken = req.header 'Authorization'
  if not authToken
    Q.reject new restify.InvalidCredentialsError(
      "Missing Authorization header.")

  else
    userData.fetch(authToken)
      .then (user) ->
        if not user
          Q.reject new restify.InvalidCredentialsError(
            "Authorization token is invalid or expired.")

        else
          user
