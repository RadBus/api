# coffeelint: disable=max_line_length

chai = require 'chai'
chai.use require 'chai-as-promised'
should = chai.should()
proxyquire = require 'proxyquire'
Q = require 'q'

# stub dependencies
request =
  '@noCallThru': true

crypto =
  '@noCallThru': true

# target library under test
target = proxyquire '../../data/user',
  'request': request
  'crypto': crypto

describe "data/user", ->
  describe "#fetch", ->
    beforeEach ->
      process.env.RADBUS_GOOGLE_API_CLIENT_ID = 'google-api-client-id'
      process.env.RADBUS_USER_ID_SALT = 'user-id-salt'

      request.get = (options, callback) ->
        options.should.have.property 'url'
        options.should.have.property 'json', true
        options.should.have.deep.property 'headers.Authorization', 'foo-token'

        process.nextTick ->
          response =
            statusCode: 200
          body =
            emails: [
              { value: 'foo@bar.com' }
            ]
            displayName: 'Foo User'

          callback null, response, body

      crypto.pbkdf2 = (password, salt, iterations, keylen, callback) ->
        password.should.be.equal 'foo@bar.com'
        salt.should.be.equal 'user-id-salt'
        iterations.should.be.equal 10000
        keylen.should.be.equal 512

        process.nextTick ->
          callback null, 'hashed-foo@bar.com'

    afterEach ->
      delete process.env.RADBUS_GOOGLE_API_CLIENT_ID
      delete process.env.RADBUS_USER_ID_SALT

    it "should return the expected error if the Google API client ID env variable isn't set", ->
      delete process.env.RADBUS_GOOGLE_API_CLIENT_ID

      target.fetch('foo-token')
        .should.eventually.be.rejected
          .and.match /Missing env variable/

    it "should return the expected error if the user ID salt env variable isn't set", ->
      delete process.env.RADBUS_USER_ID_SALT

      target.fetch('foo-token')
        .should.eventually.be.rejected
          .and.match /Missing env variable/

    it "should return the expected error if there's a problem making the Google+ API call", ->
      err = new Error "Request ERROR!"

      request.get = (options, callback) ->
        process.nextTick -> callback err

      target.fetch('foo-token')
        .should.eventually.be.rejected
          .and.equal err

    it "should return null if the Google+ API call didn't return 200", ->
      request.get = (options, callback) ->
        process.nextTick ->
          response =
            statusCode: 401
          body =
            message: "No Googles for you"

          callback null, response, body

      target.fetch('foo-token')
        .should.eventually.be.fulfilled
          .and.be.null

    it "should return the expected error if there's a problem hashing the user's email", ->
      err = new Error "Crypto ERROR!"

      crypto.pbkdf2 = (password, salt, iterations, keylen, callback) ->
        process.nextTick -> callback err

      target.fetch('foo-token')
        .should.eventually.be.rejected
          .and.equal err

    it "should return the expected user information if the Google+ API call and email hasing were successful", ->
      target.fetch('foo-token')
        .should.eventually.be.fulfilled.then (user) ->
          user.should.have.property 'id', 'hashed-foo@bar.com'
          user.should.have.property 'displayName', 'Foo User'
