# coffeelint: disable=max_line_length

chai = require 'chai'
chai.use require 'chai-as-promised'
should = chai.should()
request = require 'super-request'
helpers = require './helpers'

# build server
server = helpers.buildServer '../../api/resources/oauth2'

describe "GET /oauth2", ->
  beforeEach ->
    process.env.RADBUS_GOOGLE_API_CLIENT_ID = 'api-auth-client-id'
    process.env.RADBUS_GOOGLE_API_CLIENT_SECRET = 'api-auth-client-secret'
    process.env.RADBUS_GOOGLE_API_AUTH_SCOPES = 'api-auth-scopes'

  afterEach ->
    delete process.env.RADBUS_GOOGLE_API_AUTH_SCOPES

  it "should return 200 with expected data", ->
    request(server)
      .get('/v1/oauth2')
      .json(true)
      .expect(200)
      .expect('Content-Type', /json/)
      .end()

      .should.eventually.be.fulfilled
      .then (res) ->
        body = res.body

        body.should.have.property 'client_id', 'api-auth-client-id'
        body.should.have.property 'client_secret', 'api-auth-client-secret'
        body.should.have.property 'scopes', 'api-auth-scopes'
