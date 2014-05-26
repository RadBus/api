mongoose = require 'mongoose'

ScheduleSchema = new mongoose.Schema
  userId: { type: String, index: true }
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
