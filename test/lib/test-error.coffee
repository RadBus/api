# coffeelint: disable=max_line_length

chai = require 'chai'
chai.use require 'chai-as-promised'
should = chai.should()
expect = chai.expect

# target library under test
target = require '../../lib/error'

describe "util/error", ->
  describe "#wrapInternal()", ->
    req = {}

    describe "when an error is passed containing a 'statusCode' property", ->
      it "should return the passed error (pass through)", ->
        err = statusCode: 42
        result = target.wrapInternal req, err

        result.should.be.equal err

    describe "when an error is't passed with a 'statusCode' property", ->
      beforeEach ->
        req.header = -> null

      describe "when running locally", ->
        it "should return an InternalError with the expected generic error message", ->
          err = new Error 'VOIP'
          result = target.wrapInternal req, err

          result.message.should.be.equal 'Something got borked! ID: [none]'

      describe "when running on the server", ->
        beforeEach ->
          req.header = (name) ->
            if name is 'X-Request-ID' then 'some-request-id'

        it "should return an InternalError with a message containing the request ID", ->
          err = new Error 'VOIP'
          result = target.wrapInternal req, err

          result.message.should.be.equal 'Something got borked! ID: some-request-id'

      describe "when the passed error isn't empty", ->
        it "should return an InternalError whose 'inner' property is the specified error", ->
          err = new Error 'VOIP'
          result = target.wrapInternal req, err

          result.inner.should.be.equal err

      describe "when the passed error is empty", ->
        it "should return an InternalError whose 'inner' property is an error with a message warning of an undefined error returned by a resource action", ->
          result = target.wrapInternal req, null

          result.inner.message.should.match /An undefined error was returned by an API action/
