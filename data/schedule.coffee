Q = require 'q'
Schedule = require '../models/schedule'

exports.fetch = (googleId) ->
  # Wrap promise returned by Mongoose in a Q promise
  Q Schedule.findOne(googleId: googleId).exec()
