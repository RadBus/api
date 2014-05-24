# coffeelint: disable=max_line_length

chai = require 'chai'
chai.use require 'chai-as-promised'
should = chai.should()
request = require 'super-request'
helpers = require './helpers'
Q = require 'q'

# stub dependencies
routeData =
  fetchAll: ->
    routes = [
      { id: '123', description: 'Route 123' },
      { id: '456', description: 'Route 456' }
    ]
    Q routes
  fetchDetail: (routeId) ->
    route =
      if routeId is '123'
        id: '123'
        description: 'Route 123'
        directions: [
          {
            id: '2'
            description: 'Eastbound'
            stops: [
              { id: 'STP1', description: 'Stop 1' },
              { id: 'STP2', description: 'Stop 2' }
            ]
          },
          {
            id: '3'
            description: 'Westbound'
            stops: [
              { id: 'STP3', description: 'Stop 3' },
              { id: 'STP4', description: 'Stop 4' }
            ]
          }
        ]
      else null
    Q route

  '@noCallThru': true

# build server
server = helpers.buildServer '../../api/resources/route',
  '../../data/route': routeData

describe "GET /routes/:route", ->
  it "should return 404 if no route data exists", ->
    request(server)
      .get('/routes/456')
      .json(true)
      .expect(404)
      .end()

  it "should return 200 with the expected route data if the route exists", ->
    request(server)
      .get('/routes/123')
      .json(true)
      .expect(200)
      .expect('Content-Type', /json/)
      .end()

      .should.eventually.be.fulfilled
      .then (res) ->
        route = res.body

        route.should.be.an('object')
        route.should.have.property 'id', '123'
        route.should.have.property 'description', 'Route 123'
        route.should.have.property('directions')
          .that.is.an('array').with.length 2

        direction = route.directions[0]
        direction.should.have.property 'id', '2'
        direction.should.have.property 'description', 'Eastbound'
        direction.should.have.property('stops')
          .that.is.an('array').with.length 2
        stop = direction.stops[0]
        stop.should.have.property 'id', 'STP1'
        stop.should.have.property 'description', 'Stop 1'
        stop = direction.stops[1]
        stop.should.have.property 'id', 'STP2'
        stop.should.have.property 'description', 'Stop 2'

        direction = route.directions[1]
        direction.should.have.property 'id', '3'
        direction.should.have.property 'description', 'Westbound'
        direction.should.have.property('stops')
          .that.is.an('array').with.length 2
        stop = direction.stops[0]
        stop.should.have.property 'id', 'STP3'
        stop.should.have.property 'description', 'Stop 3'
        stop = direction.stops[1]
        stop.should.have.property 'id', 'STP4'
        stop.should.have.property 'description', 'Stop 4'
