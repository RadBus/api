# coffeelint: disable=max_line_length

chai = require 'chai'
chai.use require 'chai-as-promised'
should = chai.should()
request = require 'super-request'
helpers = require '../api/helpers'
Q = require 'q'

# stub dependencies
routeData =
  fetchAll: ->
    Q [
      { id: '123', description: 'Route 123' },
      { id: '456', description: 'Route 456' }
    ]
  '@noCallThru': true

# build server
server = helpers.buildServer '../../api/resources/route',
  '../../data/route': routeData

describe "lib/server", ->
  describe "API key checking disabled", ->
    beforeEach ->
      process.env.RADBUS_API_KEYS_ENABLED = 'false'
    afterEach ->
      delete process.env.RADBUS_API_KEYS_ENABLED

    it "#API key disabled : should return 200 with the expected routes", ->
      request(server)
        .get('/routes')
        .json(true)
        .expect(200)
        .expect('Content-Type', /json/)
        .end()
  
  describe "api-key checking enabled", ->
    beforeEach ->
      process.env.RADBUS_API_KEYS_ENABLED = 'true'
      process.env.RADBUS_API_KEYS = '1234,4321'

    afterEach ->
      delete process.env.RADBUS_API_KEYS_ENABLED
      delete process.env.RADBUS_API_KEYS

    it "should return 401 if the API key is missing", ->
      r = request(server)
        .get('/routes')

      helpers.assert401WithMissingApiKeyHeader r

    it "should return 401 if the API key is invalid", ->
      r = request(server)
        .get('/routes')
        .headers('API-Key': 'bar-token')

      helpers.assert401WithInvalidApiKeyHeader r


    it "should return 200 with the expected routes if API key is valid", ->
      request(server)
        .get('/routes')
        .headers('API-Key': '4321')
        .json(true)
        .expect(200)
        .expect('Content-Type', /json/)
        .end()

