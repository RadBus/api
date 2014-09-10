chai = require 'chai'
chai.use require 'chai-as-promised'
should = chai.should()
proxyquire = require 'proxyquire'

exports.buildServer = (resourceModulePath, stubs) ->
  # stub server dependencies
  # (none)

  # ensure server is a new instance each time
  proxyquire.noPreserveCache()
  server = proxyquire '../../lib/server', {}
  # server = require '../../lib/server'
  proxyquire.preserveCache()

  # load resource module and register with server
  resource =
    if stubs
      proxyquire(resourceModulePath, stubs)
    else
      require resourceModulePath

  resource.register server, ''

  server

exports.assert401WithMissingAuthorizationHeader = (request) ->
  request.json(true)
    .expect(401)
    .end()

    .should.eventually.be.fulfilled
    .then (res) ->
      error = res.body

      error.message.should.match /Missing Authorization header/

exports.assert401WithInvalidAuthorizationHeader = (request) ->
  request
    .json(true)
    .expect(401)
    .end()

    .should.eventually.be.fulfilled
    .then (res) ->
      error = res.body

      error.message.should.match /Authorization token is invalid or expired/

exports.assert401WithMissingApiKeyHeader = (request) ->
  request.json(true)
    .expect(401)
    .end()

    .should.eventually.be.fulfilled
    .then (res) ->
      error = res.body

      error.message.should.match /Missing API key header/

exports.assert401WithInvalidApiKeyHeader = (request) ->
  request
    .json(true)
    .expect(401)
    .end()

    .should.eventually.be.fulfilled
    .then (res) ->
      error = res.body

      error.message.should.match /API key is invalid or expired/

exports.assertAppVersionResponse = (request) ->
  request
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
