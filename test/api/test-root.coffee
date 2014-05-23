# coffeelint: disable=max_line_length

chai = require 'chai'
chai.use require 'chai-as-promised'
should = chai.should()
request = require 'super-request'
helpers = require './helpers'

# build server
server = helpers.buildServer '../../api/resources/root'

describe "GET / (root)", ->
  it "should return 200 with expected application/version structure", ->
    request(server)
      .get('/')
      .json(true)
      .expect(200)
      .expect('Content-Type', /json/)
      .end()

      .should.eventually.be.fulfilled
      .then (res) ->
        body = res.body

        body.should.be.an 'object'
        body.should.have.property 'service_name'
        body.should.have.property 'app_version'
        body.should.have.property 'api_version'
