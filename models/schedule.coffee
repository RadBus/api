mongoose = require 'mongoose'

ScheduleSchema = new mongoose.Schema
  googleId: { type: String, index: true }
  routes: [
    id: Number
    am:
      direction: Number
      stops: [String]
    pm:
      direction: Number
      stops: [String]
  ]

module.exports = mongoose.model 'schedule', ScheduleSchema
