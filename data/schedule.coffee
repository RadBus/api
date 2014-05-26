Q = require 'q'
Schedule = require '../models/schedule'

exports.fetch = (userId) ->
  # Wrap promise returned by Mongoose in a Q promise
  Q Schedule.findOne(userId: userId).exec()
