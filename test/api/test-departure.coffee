# coffeelint: disable=max_line_length

chai = require 'chai'
chai.use require 'chai-as-promised'
should = chai.should()
request = require 'super-request'
helpers = require './helpers'
Q = require 'q'
proxyquire = require 'proxyquire'
moment = require 'moment-timezone'

# stub dependencies
userData =
  '@noCallThru': true

scheduleData =
  '@noCallThru': true

routeData =
  '@noCallThru': true

departureData =
  '@noCallThru': true

security = proxyquire '../../lib/security',
  '../data/user': userData

nowMoment = {}
momentStub = ->
  if arguments.length > 0
    moment.apply null, arguments
  else
    # return new instance so it can be mutated
    # and not effect instance returned by next call
    moment nowMoment

# build server
server = helpers.buildServer '../../api/resources/departure',
  'moment-timezone': momentStub
  '../../lib/security': security
  '../../data/schedule': scheduleData
  '../../data/route': routeData
  '../../data/departure': departureData

describe "GET /departures", ->
  beforeEach ->
    process.env.RADBUS_TIMEZONE = 'America/Chicago'
    process.env.RADBUS_FUTURE_MINUTES = '60'

    userData.fetch = (authToken) ->
      user =
        if authToken is 'foo-token'
          id: 'foo'
          displayName: 'Foo User'
        else null

      Q user

    scheduleData.fetch = (userId) ->
      schedule =
        if userId is 'foo'
          userId: 'foo'
          routes: [
            {
              id: '123'
              am:
                direction: '2'
                stops: ['STP1A', 'STP2A', '42:foo stop']
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

        else null

      Q schedule

    routeData.fetchDetail = (routeId) ->
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

  afterEach ->
    # delete enviroment variables so they don't affect other tests
    delete process.env.RADBUS_TIMEZONE
    delete process.env.RADBUS_FUTURE_MINUTES

  it "should return 401 if the Authorization header is missing", ->
    r = request(server)
      .get('/departures')

    helpers.assert401WithMissingAuthorizationHeader r

  it "should return 401 if the authentication token is invalid", ->
    r = request(server)
      .get('/departures')
      .headers('Authorization': 'bar-token')

    helpers.assert401WithInvalidAuthorizationHeader r

  it "should return 200 with the expected AM departures, when it's morning", ->
    # now = 7AM Central
    nowMoment = moment '2014-05-01T07:00-05:00'

    # mock departures that return at 7AM
    departureData.fetchByRouteDirectionAndStop = (routeId, directionId, stopId) ->
      departures =
        if routeId is '123'
          # AM departures
          if directionId is '2'
            if stopId is 'STP1A'
              [
                {
                  routeId: '123'
                  time: moment '2014-05-01T07:00-05:00'
                  terminal: 'A'
                  location:
                    lat: -42
                    long: 24
                },
                {
                  routeId: '123'
                  time: moment '2014-05-01T07:30-05:00'
                },
                # this departure should not be returned
                # since it's too far into the future
                {
                  routeId: '123'
                  time: moment '2014-05-01T08:15-05:00'
                }
              ]

            else if stopId is 'STP2A'
              [
                {
                  routeId: '123'
                  time: moment '2014-05-01T07:05-05:00'
                  terminal: 'A'
                  location:
                    lat: -42
                    long: 24
                },
                {
                  routeId: '123'
                  time: moment '2014-05-01T07:35-05:00'
                },
                # this departure should not be returned
                # since it's too far into the future
                {
                  routeId: '123'
                  time: moment '2014-05-01T08:20-05:00'
                }
              ]

          # PM departures
          else if directionId is '3'
            if stopId is 'STP5A'
              [
                {
                  routeId: '123'
                  time: moment '2014-05-01T15:00-05:00'
                }
                # more data, but we won't use it since it's AM
              ]

        else if routeId is '456'
          # AM departures
          if directionId is '1'
            if stopId is 'STP1B'
              [
                {
                  routeId: '456'
                  time: moment '2014-05-01T07:10-05:00'
                  gate: 'X'
                  location:
                    lat: -42.5
                    long: 24.5
                },
                {
                  routeId: '456'
                  time: moment '2014-05-01T07:40-05:00'
                },
                # this departure should not be returned
                # since it's too far into the future
                {
                  routeId: '456'
                  time: moment '2014-05-01T08:25-05:00'
                }
              ]

          # PM departures
          else if directionId is '4'
            if stopId is 'STP4B'
              [
                {
                  routeId: '456'
                  time: moment '2014-05-01T15:05-05:00'
                }
                # more data, but we won't use it since it's AM
              ]

            else if stopId is 'STP5B'
              [
                {
                  routeId: '456'
                  time: moment '2014-05-01T15:10-05:00'
                }
                # more data, but we won't use it since it's AM
              ]

      if not departures
        departures = []

      Q departures

    departureData.fetchByRouteAndMtStopId = (routeId, stopId) ->
      departures =
        if stopId is '42' and routeId is '123'
          [
            {
              routeId: '123'
              time: moment '2014-05-01T07:06-05:00'
              terminal: 'A'
              location:
                lat: -42
                long: 24
            },
            {
              routeId: '123'
              time: moment '2014-05-01T07:36-05:00'
            },
            # this departure should not be returned
            # since it's too far into the future
            {
              routeId: '123'
              time: moment '2014-05-01T08:21-05:00'
            }
          ]

      if not departures
        departures = []

      Q departures

    request(server)
      .get('/departures')
      .json(true)
      .headers('Authorization': 'foo-token')
      .expect(200)
      .end()

      .should.eventually.be.fulfilled
        .then (res) ->
          departures = res.body
          departures.should.be.an('array')
            .with.length 8

          # expect only the AM departures, in time order, for the next hour only
          index = 0

          departure = departures[index++]
          moment(departure.time).isSame('2014-05-01T07:00-05:00')
            .should.be.true
          departure.should.have.deep.property 'route.id', '123'
          departure.should.have.deep.property 'route.terminal', 'A'
          departure.should.have.deep.property 'stop.id', 'STP1A'
          departure.should.have.deep.property 'stop.description', 'Stop 1-A'
          departure.should.not.have.deep.property 'stop.gate'
          departure.should.have.deep.property 'location.lat', -42
          departure.should.have.deep.property 'location.long', 24

          departure = departures[index++]
          moment(departure.time).isSame('2014-05-01T07:05-05:00')
            .should.be.true
          departure.should.have.deep.property 'route.id', '123'
          departure.should.have.deep.property 'route.terminal', 'A'
          departure.should.have.deep.property 'stop.id', 'STP2A'
          departure.should.have.deep.property 'stop.description', 'Stop 2-A'
          departure.should.not.have.deep.property 'stop.gate'
          departure.should.have.deep.property 'location.lat', -42
          departure.should.have.deep.property 'location.long', 24

          # stop from MT Stop ID
          departure = departures[index++]
          moment(departure.time).isSame('2014-05-01T07:06-05:00')
            .should.be.true
          departure.should.have.deep.property 'route.id', '123'
          departure.should.have.deep.property 'route.terminal', 'A'
          departure.should.have.deep.property 'stop.id', '42'
          departure.should.have.deep.property 'stop.description', 'foo stop'
          departure.should.not.have.deep.property 'stop.gate'
          departure.should.have.deep.property 'location.lat', -42
          departure.should.have.deep.property 'location.long', 24

          departure = departures[index++]
          moment(departure.time).isSame('2014-05-01T07:10-05:00')
            .should.be.true
          departure.should.have.deep.property 'route.id', '456'
          departure.should.not.have.deep.property 'route.terminal'
          departure.should.have.deep.property 'stop.id', 'STP1B'
          departure.should.have.deep.property 'stop.description', 'Stop 1-B'
          departure.should.have.deep.property 'stop.gate', 'X'
          departure.should.have.deep.property 'location.lat', -42.5
          departure.should.have.deep.property 'location.long', 24.5

          departure = departures[index++]
          moment(departure.time).isSame('2014-05-01T07:30-05:00')
            .should.be.true
          departure.should.have.deep.property 'route.id', '123'
          departure.should.not.have.deep.property 'route.terminal'
          departure.should.have.deep.property 'stop.id', 'STP1A'
          departure.should.have.deep.property 'stop.description', 'Stop 1-A'
          departure.should.not.have.deep.property 'stop.gate'
          departure.should.not.have.property 'location'

          departure = departures[index++]
          moment(departure.time).isSame('2014-05-01T07:35-05:00')
            .should.be.true
          departure.should.have.deep.property 'route.id', '123'
          departure.should.not.have.deep.property 'route.terminal'
          departure.should.have.deep.property 'stop.id', 'STP2A'
          departure.should.have.deep.property 'stop.description', 'Stop 2-A'
          departure.should.not.have.deep.property 'stop.gate'
          departure.should.not.have.property 'location'

          # stop from MT Stop ID
          departure = departures[index++]
          moment(departure.time).isSame('2014-05-01T07:36-05:00')
            .should.be.true
          departure.should.have.deep.property 'route.id', '123'
          departure.should.not.have.deep.property 'route.terminal'
          departure.should.have.deep.property 'stop.id', '42'
          departure.should.have.deep.property 'stop.description', 'foo stop'
          departure.should.not.have.deep.property 'stop.gate'
          departure.should.not.have.property 'location'

          departure = departures[index++]
          moment(departure.time).isSame('2014-05-01T07:40-05:00')
            .should.be.true
          departure.should.have.deep.property 'route.id', '456'
          departure.should.not.have.deep.property 'route.terminal'
          departure.should.have.deep.property 'stop.id', 'STP1B'
          departure.should.have.deep.property 'stop.description', 'Stop 1-B'
          departure.should.not.have.deep.property 'stop.gate'
          departure.should.not.have.property 'location'

  it "should return 200 with the expected PM departures, when it's afternoon", ->
    # now = 3PM Central
    nowMoment = moment('2014-05-01T15:00-05:00')

    # mock departures that return at 4PM
    departureData.fetchByRouteDirectionAndStop = (routeId, directionId, stopId) ->
      departures =
        if routeId is '123'
          # AM departures
          # - normally no AM departure would be returned, but including them
          #   here so we can test the departures API doesn't include them
          if directionId is '2'
            if stopId is 'STP1A'
              [
                {
                  routeId: '123'
                  time: moment '2014-05-01T07:00-05:00'
                }
              ]

            else if stopId is 'STP2A'
              [
                {
                  routeId: '123'
                  time: moment '2014-05-01T07:05-05:00'
                }
              ]

          # PM departures
          else if directionId is '3'
            if stopId is 'STP5A'
              [
                {
                  routeId: '123'
                  time: moment '2014-05-01T15:00-05:00'
                },
                {
                  routeId: '123'
                  time: moment '2014-05-01T15:30-05:00'
                },
                # this departure should not be returned
                # since it's too far into the future
                {
                  routeId: '123'
                  time: moment '2014-05-01T16:15-05:00'
                }
              ]

        else if routeId is '456'
          # AM departures
          # - normally no AM departure would be returned, but including them
          #   here so we can test the departures API doesn't include them
          if directionId is '1'
            if stopId is 'STP1B'
              [
                {
                  routeId: '456'
                  time: moment '2014-05-01T07:10-05:00'
                }
              ]

          # PM departures
          else if directionId is '4'
            if stopId is 'STP4B'
              [
                {
                  routeId: '456'
                  time: moment '2014-05-01T15:25-05:00'
                },
                # this departure should not be returned
                # since it's too far into the future
                {
                  routeId: '456'
                  time: moment '2014-05-01T16:05-05:00'
                }
              ]

            else if stopId is 'STP5B'
              [
                {
                  routeId: '456'
                  time: moment '2014-05-01T15:45-05:00'
                },
                # this departure should not be returned
                # since it's too far into the future
                {
                  routeId: '456'
                  time: moment '2014-05-01T16:10-05:00'
                }
              ]

      if not departures
        departures = []

      Q departures

    request(server)
      .get('/departures')
      .json(true)
      .headers('Authorization': 'foo-token')
      .expect(200)
      .end()

      .should.eventually.be.fulfilled
        .then (res) ->
          departures = res.body
          departures.should.be.an('array')
            .with.length 4

          # expect only the PM departures, in time order, for the next hour only
          index = 0

          departure = departures[index++]
          moment(departure.time).isSame('2014-05-01T15:00-05:00')
            .should.be.true
          departure.should.have.deep.property 'route.id', '123'
          departure.should.have.deep.property 'stop.id', 'STP5A'
          departure.should.have.deep.property 'stop.description', 'Stop 5-A'

          departure = departures[index++]
          moment(departure.time).isSame('2014-05-01T15:25-05:00')
            .should.be.true
          departure.should.have.deep.property 'route.id', '456'
          departure.should.have.deep.property 'stop.id', 'STP4B'
          departure.should.have.deep.property 'stop.description', 'Stop 4-B'

          departure = departures[index++]
          moment(departure.time).isSame('2014-05-01T15:30-05:00')
            .should.be.true
          departure.should.have.deep.property 'route.id', '123'
          departure.should.have.deep.property 'stop.id', 'STP5A'
          departure.should.have.deep.property 'stop.description', 'Stop 5-A'

          departure = departures[index++]
          moment(departure.time).isSame('2014-05-01T15:45-05:00')
            .should.be.true
          departure.should.have.deep.property 'route.id', '456'
          departure.should.have.deep.property 'stop.id', 'STP5B'
          departure.should.have.deep.property 'stop.description', 'Stop 5-B'

  it "should return 200 with an empty list when no departures exist", ->

    scheduleData.fetch = (userId) ->
      Q null

    request(server)
      .get('/departures')
      .json(true)
      .headers('Authorization': 'foo-token')
      .expect(200)
      .end()

      .should.eventually.be.fulfilled
        .then (res) ->
          departures = res.body
          departures.should.be.an('array')
            .with.length 0
