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

  describe "#fetch()", ->
    it "should return nothing if the specified schedule doesn't exist", ->
      target.fetch('foo')
        .should.eventually.be.fulfilled.then (schedule) ->
          expect(schedule).to.be.null

    it "should return an existing schedule document", ->
      Schedule.create [
        googleId: 'foo'
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
      ]
      .then ->
        target.fetch 'foo'

      .should.eventually.be.fulfilled.then (schedule) ->
        schedule.should.have.property 'googleId', 'foo'
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
