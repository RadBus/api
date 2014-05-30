# coffeelint: disable=max_line_length

chai = require 'chai'
chai.use require 'chai-as-promised'
should = chai.should()
expect = chai.expect
Q = require 'q'
proxyquire = require 'proxyquire'

# stub dependencies
userData = {}

# target library under test
target = proxyquire '../../lib/security',
  '../data/user': userData

describe "util/security", ->
  describe "#getUser()", ->
    it "it should fail with the expected InvalidCredentialsError if no Authorization header exists in the request", ->
      req =
        header: (name) -> null

      target.getUser(req)

        .should.eventually.be.rejected.then (error) ->
          error.should.have.property 'statusCode', 401
          error.should.have.property('message')
            .and.match /Missing Authorization header/

    it "it should fail with the expected InvalidCredentialsError if the authorization token is invalid/expired", ->
      userData.fetch = (authToken) -> Q()

      req =
        header: (name) ->
          if name is 'Authorization' then 'foo-token'

      target.getUser(req)

        .should.eventually.be.rejected.then (error) ->
          error.should.have.property 'statusCode', 401
          error.should.have.property('message')
            .and.match /Authorization token is invalid or expired/

    it "it should return the associated user if the authorization token was valid", ->
      user =
        id: 'foo'

      userData.fetch = (authToken) ->
        if authToken is 'foo-token' then Q(user) else Q()

      req =
        header: (name) ->
          if name is 'Authorization' then 'foo-token'

      target.getUser(req)

        .should.eventually.be.fulfilled
          .and.be.equal user
