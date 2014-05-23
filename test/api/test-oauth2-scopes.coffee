# coffeelint: disable=max_line_length

chai = require 'chai'
chai.use require 'chai-as-promised'
should = chai.should()
request = require 'super-request'
helpers = require './helpers'

# build server
server = helpers.buildServer '../../api/resources/oauth2-scopes'

describe "GET /oauth2-scopes", ->
  beforeEach ->
    process.env.RADBUS_GOOGLE_API_AUTH_SCOPES = 'api-auth-scopes'

  afterEach ->
    delete process.env.RADBUS_GOOGLE_API_AUTH_SCOPES

  it "should return 200 with expected format", ->
    request(server)
      .get('/oauth2-scopes')
      .json(true)
      .expect(200)
      .expect('Content-Type', /json/)
      .end()

      .should.eventually.be.fulfilled
      .then (res) ->
        body = res.body

        body.should.be.equal 'api-auth-scopes'
