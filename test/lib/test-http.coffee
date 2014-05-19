# coffeelint: disable=max_line_length

chai = require 'chai'
chai.use require 'chai-as-promised'
should = chai.should()
expect = chai.expect
proxyquire = require 'proxyquire'
Q = require 'q'

# stub dependencies
error = {}

# target library under test
target = proxyquire '../../lib/http',
  './error': error

describe "util/http", ->
  server = {}
  registeredRoute = null
  registeredHandler = null
  sentValue = null
  nextValue = null
  nextDeferred = null

  req = {}
  res = send: (val) -> sentValue = val

  next = (val) ->
    nextValue = val
    nextDeferred.resolve()

  beforeEach ->
    server = {}
    registeredRoute = null
    registeredHandler = null
    sentValue = null
    nextValue = null
    nextDeferred = Q.defer()

  describe "#get()", ->
    beforeEach ->
      server =
        get: (route, handler) ->
          registeredRoute = route
          registeredHandler = handler

    it "should register an HTTP GET route to a handler", ->
      action = -> Q()
      target.get server, '/foo', action

      registeredRoute.should.be.equal '/foo'
      expect(registeredHandler).should.not.be.empty

    describe "registered handler", ->

      it "should should send the action value to the HTTP response and call 'next', when invoked with a successful action", ->
        action = -> Q 'bar'
        target.get server, '/foo', action

        registeredHandler req, res, next

        nextDeferred.promise.should.eventually.be.fulfilled.then ->
          sentValue.should.be.equal 'bar'
          expect(nextValue).to.not.exist

      it "should call 'next' with a wrapped error, when invoked with a failed action", ->
        action = -> Q.reject('bar')
        target.get server, '/foo', action

        wrappedError = new Error 'VOIP!'
        error.wrapInternal = (req, inner) ->
          wrappedError.inner = inner
          wrappedError

        registeredHandler req, res, next

        nextDeferred.promise.should.eventually.be.fulfilled.then ->
          expect(sentValue).to.not.exist
          nextValue.should.be.equal wrappedError
          nextValue.inner.should.be.equal 'bar'
