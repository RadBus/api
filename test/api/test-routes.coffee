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
    Q [
      { id: '123', description: 'Route 123' },
      { id: '456', description: 'Route 456' }
    ]
  '@noCallThru': true

# build server
server = helpers.buildServer '../../api/resources/route',
  '../../data/route': routeData

describe "GET /routes", ->
  it "should return 200 with the expected routes", ->
    request(server)
      .get('/routes')
      .json(true)
      .expect(200)
      .expect('Content-Type', /json/)
      .end()

      .should.eventually.be.fulfilled
      .then (res) ->
        body = res.body

        body.should.be.an('array')
          .with.length 2

        route = body[0]
        route.should.have.property 'id', '123'
        route.should.have.property 'description', 'Route 123'

        route = body[1]
        route.should.have.property 'id', '456'
        route.should.have.property 'description', 'Route 456'
