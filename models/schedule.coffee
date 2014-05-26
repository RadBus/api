mongoose = require 'mongoose'

ScheduleSchema = new mongoose.Schema
  googleId: { type: String, index: true }
  routes: [
    id: String
    am:
      direction: String
      stops: [String]
    pm:
      direction: String
      stops: [String]
  ]

module.exports = mongoose.model 'schedule', ScheduleSchema
