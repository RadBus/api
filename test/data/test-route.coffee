# coffeelint: disable=max_line_length

chai = require 'chai'
chai.use require 'chai-as-promised'
should = chai.should()
proxyquire = require 'proxyquire'
Q = require 'q'

# stub dependencies
nextrip = {}

# target library under test
target = proxyquire '../../data/route',
  './nextrip': nextrip

describe "data/route", ->
  describe "#fetchAll", ->
    callApiJson = []

    beforeEach ->
      nextrip.callApi = (url, state) ->
        Q
          state: state
          json: if url is 'Routes' then callApiJson

    afterEach ->
      callApiJson = []

    it "should return an empty array if there are no routes", ->
      target.fetchAll()
        .should.eventually.be.fulfilled
          .and.be.an('array').that.has.length 0

    it "should return the expected route list if routes exist", ->
      callApiJson = [
        { Route: '123', Description: 'Route 123 Desciption' },
        { Route: '456', Description: 'Route 456 Desciption' }
      ]

      target.fetchAll()
        .should.eventually.be.fulfilled
          .and.be.an('array').that.has.length(2)
          .and.then (routes) ->
            route = routes[0]
            route.should.have.property 'id', '123'
            route.should.have.property 'description', 'Route 123 Desciption'

            route = routes[1]
            route.should.have.property 'id', '456'
            route.should.have.property 'description', 'Route 456 Desciption'

  describe "#fetchDetail", ->
    beforeEach ->
      nextrip.callApi = (url, state) ->
        Q
          state: state
          json:
            if url is 'Directions/123'
              [
                { Value: '2', Text: 'EASTBOUND' },
                { Value: '3', Text: 'WESTBOUND' }
              ]
            else if url is 'Stops/123/2'
              [
                { Value: 'STP1', Text: 'Stop 1' },
                { Value: 'STP2', Text: 'Stop 2' }
              ]
            else if url is 'Stops/123/3'
              [
                { Value: 'STP3', Text: 'Stop 3' },
                { Value: 'STP4', Text: 'Stop 4' }
              ]
            else []

    it "should return null if the specified route doesn't exist", ->
      target.fetchDetail '456'
        .should.eventually.be.fulfilled
          .and.be.an('array').that.has.length 0

    it "should return the expected route detail if it exists", ->
      target.fetchDetail '123'
        .should.eventually.be.fulfilled
          .and.be.an('array').that.has.length(2)
          .and.then (directions) ->
            direction = directions[0]
            direction.should.have.property 'id', '2'
            direction.should.have.property 'description', 'Eastbound'
            direction.should.have.property 'stops'
              .that.is.an('array').that.has.length 2
            stop = direction.stops[0]
            stop.should.have.property 'id', 'STP1'
            stop.should.have.property 'description', 'Stop 1'
            stop = direction.stops[1]
            stop.should.have.property 'id', 'STP2'
            stop.should.have.property 'description', 'Stop 2'

            direction = directions[1]
            direction.should.have.property 'id', '3'
            direction.should.have.property 'description', 'Westbound'
            direction.should.have.property 'stops'
              .that.is.an('array').that.has.length 2
            stop = direction.stops[0]
            stop.should.have.property 'id', 'STP3'
            stop.should.have.property 'description', 'Stop 3'
            stop = direction.stops[1]
            stop.should.have.property 'id', 'STP4'
            stop.should.have.property 'description', 'Stop 4'
