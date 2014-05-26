# coffeelint: disable=max_line_length

chai = require 'chai'
chai.use require 'chai-as-promised'
should = chai.should()
request = require 'super-request'
helpers = require './helpers'
Q = require 'q'

# stub dependencies
scheduleDocument = {}
scheduleData =
  fetch: (userId) ->
    Q if userId is 'foo' then scheduleDocument else null

  '@noCallThru': true

routeData =
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
              { id: 'STP1A', description: 'Stop 1-A' },
              { id: 'STP2A', description: 'Stop 2-A' },
              { id: 'STP3A', description: 'Stop 3-A' },
              { id: 'STP4A', description: 'Stop 4-A' },
              { id: 'STP5A', description: 'Stop 5-A' }
            ]
          },
          {
            id: '3'
            description: 'Westbound'
            stops: [
              { id: 'STP5A', description: 'Stop 5-A' },
              { id: 'STP4A', description: 'Stop 4-A' },
              { id: 'STP3A', description: 'Stop 3-A' },
              { id: 'STP2A', description: 'Stop 2-A' },
              { id: 'STP1A', description: 'Stop 1-A' }
            ]
          }
        ]
      else if routeId is '456'
        id: '456'
        description: 'Route 456'
        directions: [
          {
            id: '1'
            description: 'Northbound'
            stops: [
              { id: 'STP1B', description: 'Stop 1-B' },
              { id: 'STP2B', description: 'Stop 2-B' },
              { id: 'STP3B', description: 'Stop 3-B' },
              { id: 'STP4B', description: 'Stop 4-B' },
              { id: 'STP5B', description: 'Stop 5-B' }
            ]
          },
          {
            id: '4'
            description: 'Southbound'
            stops: [
              { id: 'STP5B', description: 'Stop 5-B' },
              { id: 'STP4B', description: 'Stop 4-B' },
              { id: 'STP3B', description: 'Stop 3-B' },
              { id: 'STP2B', description: 'Stop 2-B' },
              { id: 'STP1B', description: 'Stop 1-B' }
            ]
          }
        ]
      else null
    Q route

  '@noCallThru': true

userData =
  fetch: (authToken) ->
    user =
      if authToken is 'foo-token'
        id: 'foo'
        displayName: 'Foo User'
      else null

    Q user

  '@noCallThru': true

# build server
server = helpers.buildServer '../../api/resources/schedule',
  '../../data/schedule': scheduleData
  '../../data/route': routeData
  '../../data/user': userData

describe "GET /schedule", ->
  beforeEach ->
    scheduleDocument =
      googleId: 'foo'
      routes: [
        {
          id: '123'
          am:
            direction: '2'
            stops: ['STP1A', 'STP2A']
          pm:
            direction: '3'
            stops: ['STP5A']
        },
        {
          id: '456'
          am:
            direction: '1'
            stops: ['STP1B']
          pm:
            direction: '4'
            stops: ['STP4B', 'STP5B']
        }
      ]

  it "should return 401 if no Authorization header is passed", ->
    request(server)
      .get('/schedule')
      .json(true)
      .expect(401)
      .end()

      .should.eventually.be.fulfilled
      .then (res) ->
        error = res.body

        error.message.should.match /Missing Authorization header/

  it "should return 401 if the authentication token is invalid", ->
    request(server)
      .get('/schedule')
      .headers('Authorization': 'bar-token')
      .json(true)
      .expect(401)
      .end()

      .should.eventually.be.fulfilled
      .then (res) ->
        error = res.body

        error.message.should.match /Authorization token is invalid or expired/

  it "should return 200 with the expected user and route information", ->
    request(server)
      .get('/schedule')
      .headers('Authorization': 'foo-token')
      .json(true)
      .expect(200)
      .end()

      .should.eventually.be.fulfilled
      .then (res) ->
        schedule = res.body

        schedule.should.have.property 'user_display_name', 'Foo User'
        schedule.should.not.have.property 'missing_data'
        schedule.should.have.property('routes')
          .that.is.an('array').with.length 2

        route = schedule.routes[0]
        route.should.have.property 'id', '123'
        route.should.have.property 'description', 'Route 123'
        route.should.have.property('am')
          .that.is.an('object')
        am = route.am
        am.should.have.deep.property 'direction.id', '2'
        am.should.have.deep.property 'direction.description', 'Eastbound'
        am.should.have.property('stops')
          .that.is.an('array').with.length 2
        stops = am.stops
        stop = stops[0]
        stop.should.have.property 'id', 'STP1A'
        stop.should.have.property 'description', 'Stop 1-A'
        stop = stops[1]
        stop.should.have.property 'id', 'STP2A'
        stop.should.have.property 'description', 'Stop 2-A'
        route.should.have.property('pm')
          .that.is.an('object')
        pm = route.pm
        pm.should.have.deep.property 'direction.id', '3'
        pm.should.have.deep.property 'direction.description', 'Westbound'
        pm.should.have.property('stops')
          .that.is.an('array').with.length 1
        stops = pm.stops
        stop = stops[0]
        stop.should.have.property 'id', 'STP5A'
        stop.should.have.property 'description', 'Stop 5-A'

        route = schedule.routes[1]
        route.should.have.property 'id', '456'
        route.should.have.property 'description', 'Route 456'
        route.should.have.property('am')
          .that.is.an('object')
        am = route.am
        am.should.have.deep.property 'direction.id', '1'
        am.should.have.deep.property 'direction.description', 'Northbound'
        am.should.have.property('stops')
          .that.is.an('array').with.length 1
        stops = am.stops
        stop = stops[0]
        stop.should.have.property 'id', 'STP1B'
        stop.should.have.property 'description', 'Stop 1-B'
        route.should.have.property('pm')
          .that.is.an('object')
        pm = route.pm
        pm.should.have.deep.property 'direction.id', '4'
        pm.should.have.deep.property 'direction.description', 'Southbound'
        pm.should.have.property('stops')
          .that.is.an('array').with.length 2
        stops = pm.stops
        stop = stops[0]
        stop.should.have.property 'id', 'STP4B'
        stop.should.have.property 'description', 'Stop 4-B'
        stop = stops[1]
        stop.should.have.property 'id', 'STP5B'
        stop.should.have.property 'description', 'Stop 5-B'

  it "should return 200 with 'missing' descriptions if a schedule route no longer exists", ->
    scheduleDocument.routes[0].id = '789'

    request(server)
      .get('/schedule')
      .headers('Authorization': 'foo-token')
      .json(true)
      .expect(200)
      .end()

      .should.eventually.be.fulfilled
      .then (res) ->
        schedule = res.body

        schedule.should.have.property 'missing_data', true

        route = schedule.routes[0]
        route.should.have.property 'id', '789'
        route.should.have.property 'description', '(unknown route)'
        route.should.have.deep.property 'am.direction.description', '(unknown direction)'
        route.should.have.deep.property 'am.stops[0].description', '(unknown stop)'
        route.should.have.deep.property 'am.stops[1].description', '(unknown stop)'
        route.should.have.deep.property 'pm.direction.description', '(unknown direction)'
        route.should.have.deep.property 'pm.stops[0].description', '(unknown stop)'

  it "should return 200 with 'missing' descriptions if a schedule route's direction no longer exists", ->
    scheduleDocument.routes[0].am.direction = '42'

    request(server)
      .get('/schedule')
      .headers('Authorization': 'foo-token')
      .json(true)
      .expect(200)
      .end()

      .should.eventually.be.fulfilled
      .then (res) ->
        schedule = res.body

        schedule.should.have.property 'missing_data', true

        route = schedule.routes[0]
        route.should.have.property 'id', '123'
        route.should.have.property 'description', 'Route 123'
        route.should.have.deep.property 'am.direction.description', '(unknown direction)'
        route.should.have.deep.property 'am.stops[0].description', '(unknown stop)'
        route.should.have.deep.property 'am.stops[1].description', '(unknown stop)'
        route.should.have.deep.property 'pm.direction.description', 'Westbound'
        route.should.have.deep.property 'pm.stops[0].description', 'Stop 5-A'

  it "should return 200 with 'missing' descriptions if a schedule route direction's stop no longer exists", ->
    scheduleDocument.routes[0].am.stops[0] = 'STP42'

    request(server)
      .get('/schedule')
      .headers('Authorization': 'foo-token')
      .json(true)
      .expect(200)
      .end()

      .should.eventually.be.fulfilled
      .then (res) ->
        schedule = res.body

        schedule.should.have.property 'missing_data', true

        route = schedule.routes[0]
        route.should.have.property 'id', '123'
        route.should.have.property 'description', 'Route 123'
        route.should.have.deep.property 'am.direction.description', 'Eastbound'
        route.should.have.deep.property 'am.stops[0].description', '(unknown stop)'
        route.should.have.deep.property 'am.stops[1].description', 'Stop 2-A'
        route.should.have.deep.property 'pm.direction.description', 'Westbound'
        route.should.have.deep.property 'pm.stops[0].description', 'Stop 5-A'
