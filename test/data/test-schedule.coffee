# coffeelint: disable=max_line_length

chai = require 'chai'
chai.use require 'chai-as-promised'
should = chai.should()
expect = chai.expect

# data
mockgoose = require 'mockgoose'
mockgoose(require 'mongoose')
Schedule = require '../../models/schedule'

# target library under test
target = require '../../data/schedule'

describe "data/schedule", ->
  beforeEach ->
    mockgoose.reset()

  assertFooSchedule = (schedule) ->
    schedule.should.have.property 'userId', 'foo'
    schedule.should.have.property 'routes'
      .that.is.an('array').with.length(2)
    routes = schedule.routes

    route = routes[0]
    route.should.have.property 'id', '123'
    route.should.have.property 'am'
      .that.is.an 'object'
    am = route.am
    am.should.have.property 'direction', '1'
    am.should.have.property 'stops'
      .that.is.an 'array'
      .with.length 2
      .and.have.members ['STOP1', 'STOP2']
    route.should.have.property 'pm'
      .that.is.an 'object'
    pm = route.pm
    pm.should.have.property 'direction', '2'
    pm.should.have.property 'stops'
      .that.is.an 'array'
      .with.length 2
      .and.have.members ['STOP3', 'STOP4']

    route = routes[1]
    route.should.have.property 'id', '456'
    route.should.have.property 'am'
      .that.is.an('object')
    am = route.am
    am.should.have.property 'direction', '3'
    am.should.have.property 'stops'
      .that.is.an 'array'
      .with.length 2
      .and.have.members ['STOP5', 'STOP6']
    route.should.have.property 'pm'
      .that.is.an 'object'
    pm = route.pm
    pm.should.have.property 'direction', '4'
    pm.should.have.property 'stops'
      .that.is.an 'array'
      .with.length 2
      .and.have.members ['STOP7', 'STOP8']

  fooSchedule =
    userId: 'foo'
    routes: [
      {
        id: '123'
        am:
          direction: '1'
          stops: ['STOP1', 'STOP2']
        pm:
          direction: '2'
          stops: ['STOP3', 'STOP4']
      },
      {
        id: '456'
        am:
          direction: '3'
          stops: ['STOP5', 'STOP6']
        pm:
          direction: '4'
          stops: ['STOP7', 'STOP8']
      }
    ]

  barSchedule =
    userId: 'bar'
    routes: [
      {
        id: '789'
        am:
          direction: '3'
          stops: ['STOP9', 'STOP10']
        pm:
          direction: '4'
          stops: ['STOP11', 'STOP12']
      },
      {
        id: '123'
        am:
          direction: '1'
          stops: ['STOP13', 'STOP14']
        pm:
          direction: '2'
          stops: ['STOP15', 'STOP16']
      }
    ]

  describe "#upsert()", ->
    it "should insert a new document if one with the same user ID didn't already exist", ->
      Schedule.create [
        barSchedule
      ]
      .then ->
        Schedule.find().exec()

      .should.eventually.be.fulfilled
        .and.have.length(1)

      .then ->
        target.upsert fooSchedule
      .then ->
        Schedule.find().exec()

      .should.eventually.be.fulfilled
        .and.have.length(2)
        .then (schedules) ->
          schedule = schedules[0]
          schedule.userId.should.be.equal 'bar'

          schedule = schedules[1]
          assertFooSchedule schedule

    it "should update an existing document if one with the same user ID already exists", ->
      Schedule.create [
        barSchedule,
        {
          userId: 'foo'
          routes: [
            {
              id: '42'
              am:
                direction: '1'
                stops: ['STOP42', 'STOP43']
              pm:
                direction: '2'
                stops: ['STOP44', 'STOP45']
            }          ]
        }
      ]
      .then ->
        Schedule.find().exec()

      .should.eventually.be.fulfilled
        .and.have.length(2)

      .then ->
        target.upsert fooSchedule
      .then ->
        Schedule.find().exec()

      .should.eventually.be.fulfilled
        .and.have.length(2)
        .then (schedules) ->
          schedule = schedules[0]
          schedule.userId.should.be.equal 'bar'

          schedule = schedules[1]
          assertFooSchedule schedule

  describe "#fetch()", ->
    it "should return nothing if the specified schedule doesn't exist", ->
      target.fetch('foo')
        .should.eventually.be.fulfilled.then (schedule) ->
          expect(schedule).to.be.null

    it "should return an existing schedule document", ->
      Schedule.create [
        fooSchedule,
        barSchedule
      ]
      .then ->
        target.fetch 'foo'

      .should.eventually.be.fulfilled
        .then assertFooSchedule

  describe "#delete()", ->
    it "should return an empty set if the specified schedule doesn't exist", ->
      target.remove('foo')
        .should.eventually.be.fulfilled.then (schedule) ->
          expect(schedule).to.have.length(0)

    it "should delete an existing schedule document", ->
      Schedule.create [
        barSchedule
      ]
      .then ->
        Schedule.find().exec()

      .should.eventually.be.fulfilled
        .and.have.length(1)

      .then ->
        target.remove barSchedule
      .then ->
        Schedule.find().exec()

      .should.eventually.be.fulfilled
        .and.have.length(0)

