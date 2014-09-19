Q = require 'q'
Schedule = require '../models/schedule'

exports.fetch = (userId) ->
  p =
    Schedule.findOne
      userId: userId
    .exec()

  # Wrap promise returned by Mongoose in a Q promise
  Q p

exports.upsert = (schedule) ->
  p =
    Schedule.update
      userId: schedule.userId,
      schedule,
      upsert: true
    .exec()

  # Wrap promise returned by Mongoose in a Q promise
  Q p

exports.remove = (schedule) ->
  p =
    Schedule.findOne
      userId: schedule.userId
    .remove().exec()

  # Wrap promise returned by Mongoose in a Q promise
  Q p


