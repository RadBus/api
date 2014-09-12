# coffeelint: disable=max_line_length

chai = require 'chai'
chai.use require 'chai-as-promised'
should = chai.should()
request = require 'super-request'
helpers = require './helpers'

# build server
server = helpers.buildServer '../../api/resources/root'

describe "GET / (root)", ->

  describe "api-key disabled", ->
    beforeEach ->
      process.env.RADBUS_API_KEYS_ENABLED = 'false'
    afterEach ->
      delete process.env.RADBUS_API_KEYS_ENABLED
  
    it "should return 200 with expected application/version structure", ->
      r = request(server)
        .get('/')

      helpers.assertAppVersionResponse r

  describe "api-key enabled", ->
    beforeEach ->
      process.env.RADBUS_API_KEYS_ENABLED = 'true'
      process.env.RADBUS_API_KEYS = '1234,4321'

    afterEach ->
      delete process.env.RADBUS_API_KEYS_ENABLED
      delete process.env.RADBUS_API_KEYS

    it "should return 200 with expected application/version structure", ->
      r = request(server)
        .get('/')

      helpers.assertAppVersionResponse r
