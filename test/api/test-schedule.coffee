# coffeelint: disable=max_line_length

chai = require 'chai'
chai.use require 'chai-as-promised'
should = chai.should()
request = require 'super-request'
helpers = require './helpers'
Q = require 'q'
proxyquire = require 'proxyquire'

# stub dependencies
userData =
  fetch: (authToken) ->
    user =
      if authToken is 'foo-token'
        id: 'foo'
        displayName: 'Foo User'
      else null

    Q user

  '@noCallThru': true

scheduleDocument = {}
scheduleData =
  fetch: (userId) ->
    Q if userId is 'foo' then scheduleDocument else null

  '@noCallThru': true

security = proxyquire '../../lib/security',
  '../data/user': userData

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
      else if routeId is '321'
        id: '321'
        description: 'Route 321'
        directions: [
          {
            id: '2'
            description: 'Eastbound'
            stops: [
              { id: 'STP1C', description: 'Stop 1-C' }
            ]
          },
          {
            id: '3'
            description: 'Westbound'
            stops: [
              { id: 'STP2C', description: 'Stop 2-C' }
            ]
          }
        ]
      else null
    Q route

  '@noCallThru': true

# build server
server = helpers.buildServer '../../api/resources/schedule',
  '../../lib/security': security
  '../../data/schedule': scheduleData
  '../../data/route': routeData

describe "GET /schedule", ->
  beforeEach ->
    scheduleDocument =
      userId: 'foo'
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

  it "should return 401 if the Authorization header is missing", ->
    r = request(server)
      .get('/schedule')

    helpers.assert401WithMissingAuthorizationHeader r

  it "should return 401 if the authentication token is invalid", ->
    r = request(server)
      .get('/schedule')
      .headers('Authorization': 'bar-token')

    helpers.assert401WithInvalidAuthorizationHeader r

  it "should return 200 with the expected user and route information", ->
    request(server)
      .get('/schedule')
      .json(true)
      .headers('Authorization': 'foo-token')
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
      .json(true)
      .headers('Authorization': 'foo-token')
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
      .json(true)
      .headers('Authorization': 'foo-token')
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
      .json(true)
      .headers('Authorization': 'foo-token')
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

describe "POST /schedule/routes", ->
  beforeEach ->
    scheduleDocument =
      _id: 'foo-doc-id'
      userId: 'foo'
      routes: [
        {
          id: '123'
          am:
            direction: '2'
            stops: ['STP1A', 'STP2A']
          pm:
            direction: '3'
            stops: ['STP5A']
        }
      ]
      toObject: ->
        scheduleDocument.toObjectCalled = true
        scheduleDocument
      toObjectCalled: false

  it "should return 401 if the Authorization header is missing", ->
    r = request(server)
      .post('/schedule/routes')

    helpers.assert401WithMissingAuthorizationHeader r

  it "should return 401 if the authentication token is invalid", ->
    r = request(server)
      .post('/schedule/routes')
      .headers('Authorization': 'bar-token')

    helpers.assert401WithInvalidAuthorizationHeader r

  describe "should return 400 with expected validation errors if", ->
    assert400WithValidationError = (route, matchRegEx) ->
      request(server)
        .post('/schedule/routes')
        .json(route)
        .headers('Authorization': 'foo-token')
        .expect(400)
        .end()

        .should.eventually.be.fulfilled
        .then (res) ->
          error = res.body

          error.should.have.property('message')
            .and.match matchRegEx

    it "no route was passed", ->
      assert400WithValidationError true,
        /Route is required/

    it "the route does not contain a route ID", ->
      assert400WithValidationError
        am:
          direction: '1'
          stops: ['STP42', 'STP43']
        pm:
          direction: '2'
          stops: ['STP44', 'STP45'],

        /Route ID is required/

    it "the route ID is invalid", ->
      assert400WithValidationError
        id: '42'
        am:
          direction: '1'
          stops: ['STP42', 'STP43']
        pm:
          direction: '2'
          stops: ['STP44', 'STP45'],

        /Invalid route ID/

    it "the route does not contain an AM section", ->
      assert400WithValidationError
        id: '456'
        pm:
          direction: '4'
          stops: ['STP4B', 'STP5B'],

        /AM section is required/

    it "the route does not contain an PM section", ->
      assert400WithValidationError
        id: '456'
        am:
          direction: '1'
          stops: ['STP1B'],

        /PM section is required/

    it "the AM section does not contain a direction", ->
      assert400WithValidationError
        id: '456'
        am:
          stops: ['STP1B']
        pm:
          direction: '4'
          stops: ['STP4B', 'STP5B'],

        /AM section direction is required/

    it "the PM section does not contain a direction", ->
      assert400WithValidationError
        id: '456'
        am:
          direction: '1'
          stops: ['STP1B']
        pm:
          stops: ['STP4B', 'STP5B'],

        /PM section direction is required/

    it "the AM section's direction is invalid", ->
      assert400WithValidationError
        id: '456'
        am:
          direction: '42'
          stops: ['STP1B']
        pm:
          direction: '4'
          stops: ['STP4B', 'STP5B'],

        /Invalid AM section direction: 42/

    it "the PM section's direction is invalid", ->
      assert400WithValidationError
        id: '456'
        am:
          direction: '1'
          stops: ['STP1B']
        pm:
          direction: '42'
          stops: ['STP4B', 'STP5B'],

        /Invalid PM section direction: 42/

    it "the AM section does not contain at least one stop", ->
      assert400WithValidationError
        id: '456'
        am:
          direction: '1'
        pm:
          direction: '4'
          stops: ['STP4B', 'STP5B'],

        /AM section must contain at least one stop/

    it "an AM section's stop is invalid", ->
      assert400WithValidationError
        id: '456'
        am:
          direction: '1'
          stops: ['STP1BX']
        pm:
          direction: '4'
          stops: ['STP4B', 'STP5B'],

        /Invalid AM section stop: STP1BX/

    it "the PM section does not contain at least one stop", ->
      assert400WithValidationError
        id: '456'
        am:
          direction: '1'
          stops: ['STP1B']
        pm:
          direction: '4',

        /PM section must contain at least one stop/

    it "a PM section's stop is invalid", ->
      assert400WithValidationError
        id: '456'
        am:
          direction: '1'
          stops: ['STP1B']
        pm:
          direction: '4'
          stops: ['STP4BX', 'STP5B'],

        /Invalid PM section stop: STP4BX/

  it "should return 201 and create a schedule with a new route if the user's schedule did not already exist", ->
    scheduleDocument = null

    didUpsert = false
    updatedSchedule = null

    scheduleData.upsert = (schedule) ->
      updatedSchedule = schedule
      didUpsert = true
      Q()

    request(server)
      .post('/schedule/routes')
      .json({
        id: '456'
        am:
          direction: '1'
          stops: ['STP1B']
        pm:
          direction: '4'
          stops: ['STP4B', 'STP5B'],
      })
      .headers('Authorization': 'foo-token')
      .expect(201)
      .end()

      .should.eventually.be.fulfilled
        .then ->
          didUpsert.should.be.true

          updatedSchedule.routes.should.have.length 1

          route = updatedSchedule.routes[0]
          route.should.have.property 'id', '456'

          route.should.have.property('am')
            .that.is.an 'object'
          am = route.am
          am.should.have.property 'direction', '1'
          am.should.have.property 'stops'
            .that.is.an('array').with.length 1
          am.should.have.deep.property 'stops[0]', 'STP1B'

          route.should.have.property('pm')
            .that.is.an 'object'
          pm = route.pm
          pm.should.have.property 'direction', '4'
          pm.should.have.property 'stops'
            .that.is.an('array').with.length 2
          pm.should.have.deep.property 'stops[0]', 'STP4B'
          pm.should.have.deep.property 'stops[1]', 'STP5B'

  it "should return 201 and add the route to the schedule if the route did not already exist", ->
    didUpsert = false
    updatedSchedule = null

    scheduleData.upsert = (schedule) ->
      updatedSchedule = schedule
      didUpsert = true
      Q()

    request(server)
      .post('/schedule/routes')
      .json({
        id: '456'
        am:
          direction: '1'
          stops: ['STP1B']
        pm:
          direction: '4'
          stops: ['STP4B', 'STP5B'],
      })
      .headers('Authorization': 'foo-token')
      .expect(201)
      .end()

      .should.eventually.be.fulfilled
        .then ->
          didUpsert.should.be.true

          updatedSchedule.routes.should.have.length 2

          route = updatedSchedule.routes[0]
          route.should.have.property 'id', '123'

          route = updatedSchedule.routes[1]
          route.should.have.property 'id', '456'

          route.should.have.property('am')
            .that.is.an 'object'
          am = route.am
          am.should.have.property 'direction', '1'
          am.should.have.property 'stops'
            .that.is.an('array').with.length 1
          am.should.have.deep.property 'stops[0]', 'STP1B'

          route.should.have.property('pm')
            .that.is.an 'object'
          pm = route.pm
          pm.should.have.property 'direction', '4'
          pm.should.have.property 'stops'
            .that.is.an('array').with.length 2
          pm.should.have.deep.property 'stops[0]', 'STP4B'
          pm.should.have.deep.property 'stops[1]', 'STP5B'

  it "should return 204 and update the route in the schedule if the route did already exist", ->
    didUpsert = false
    updatedSchedule = null

    scheduleData.upsert = (schedule) ->
      updatedSchedule = schedule
      didUpsert = true
      Q()

    request(server)
      .post('/schedule/routes')
      .json({
        id: '123'
        am:
          direction: '2'
          stops: ['STP1A']
        pm:
          direction: '3'
          stops: ['STP4A', 'STP5A'],
      })
      .headers('Authorization': 'foo-token')
      .expect(204)
      .end()

      .should.eventually.be.fulfilled
        .then ->
          didUpsert.should.be.true

          updatedSchedule.should.have.property 'toObjectCalled', true
          updatedSchedule.should.not.have.property '_id'

          updatedSchedule.routes.should.have.length 1

          route = updatedSchedule.routes[0]
          route.should.have.property 'id', '123'

          route.should.have.property('am')
            .that.is.an 'object'
          am = route.am
          am.should.have.property 'direction', '2'
          am.should.have.property 'stops'
            .that.is.an('array').with.length 1
          am.should.have.deep.property 'stops[0]', 'STP1A'

          route.should.have.property('pm')
            .that.is.an 'object'
          pm = route.pm
          pm.should.have.property 'direction', '3'
          pm.should.have.property 'stops'
            .that.is.an('array').with.length 2
          pm.should.have.deep.property 'stops[0]', 'STP4A'
          pm.should.have.deep.property 'stops[1]', 'STP5A'

describe "DELETE /schedule/routes/:route", ->
  beforeEach ->
    scheduleDocument =
      _id: 'foo-doc-id'
      userId: 'foo'
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
        },
        {
          id: '321'
          am:
            direction: '2'
            stops: ['STP1C']
          pm:
            direction: '3'
            stops: ['STP2C']
        }
      ]
      toObject: ->
        scheduleDocument.toObjectCalled = true
        scheduleDocument
      toObjectCalled: false

  it "should return 401 if the Authorization header is missing", ->
    r = request(server)
      .del('/schedule/routes/456')

    helpers.assert401WithMissingAuthorizationHeader r

  it "should return 401 if the authentication token is invalid", ->
    r = request(server)
      .del('/schedule/routes/456')
      .headers('Authorization': 'bar-token')

    helpers.assert401WithInvalidAuthorizationHeader r

  it "should return 400 with expected validation errors if the user's schedule doesn't exist", ->
    scheduleDocument = null

    request(server)
      .del('/schedule/routes/42')
      .headers('Authorization': 'foo-token')
      .json(true)
      .expect(400)
      .end()

      .should.eventually.be.fulfilled
        .then (res) ->
          error = res.body

          error.should.have.property('message')
            .and.match /User does not yet have a schedule/

  it "should return 400 with expected validation errors if the specified route doesn't exist in the user's schedule", ->
    request(server)
      .del('/schedule/routes/42')
      .headers('Authorization': 'foo-token')
      .json(true)
      .expect(400)
      .end()

      .should.eventually.be.fulfilled
        .then (res) ->
          error = res.body

          error.should.have.property('message')
            .and.match /Schedule does not contain route 42/

  it "should return 204 and delete the specified route in the user's schedule", ->
    didUpsert = false
    updatedSchedule = null

    scheduleData.upsert = (schedule) ->
      updatedSchedule = schedule
      didUpsert = true
      Q()

    request(server)
      .del('/schedule/routes/456')
      .headers('Authorization': 'foo-token')
      .json(true)
      .expect(204)
      .end()

      .should.eventually.be.fulfilled
        .then ->
          didUpsert.should.be.true

          updatedSchedule.should.have.property 'toObjectCalled', true
          updatedSchedule.should.not.have.property '_id'

          updatedSchedule.routes.should.have.length 2

          route = updatedSchedule.routes[0]
          route.should.have.property 'id', '123'

          route = updatedSchedule.routes[1]
          route.should.have.property 'id', '321'
