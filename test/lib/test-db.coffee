# coffeelint: disable=max_line_length

chai = require 'chai'
chai.use require 'chai-as-promised'
should = chai.should()
proxyquire = require 'proxyquire'

# stub dependencies
mongoose = {}

# target library under test
target = proxyquire '../../lib/db',
  mongoose: mongoose

describe "util/db", ->
  beforeEach ->
    mongoose.connection =
      replica: false
      host: 'foo'
      port: 4242
      name: 'bar'
      db:
        serverConfig:
          ssl: false

  describe "#open()", ->
    beforeEach ->
      process.env.MONGOHQ_URL = 'foo://uri'

    it "should connect using environment variable URI", ->
      mongoose.connection.on = (event, callback) ->
        if event is 'connected'
          process.nextTick callback

      wasOpened = no
      mongoose.connect = (uri) ->
        if uri is 'foo://uri' then wasOpened = true

      p = target.open()
      p.should.eventually.be.fulfilled.then ->
        wasOpened.should.be.true

    it "should fail if there's a connection error", ->
      err = new Error 'VOIP!'
      mongoose.connection.on = (event, callback) ->
        if event is 'error'
          process.nextTick -> callback err

      mongoose.connect = ->

      p = target.open()
      p.should.eventually.be.rejected
        .and.be.equal err

  describe "#close()", ->
    it "should disconnect from the database", ->
      mongoose.connection.on = (event, callback) ->
        if event is 'disconnected'
          process.nextTick callback

      wasClosed = no
      mongoose.connection.close = -> wasClosed = true

      p = target.close()
      p.should.eventually.be.fulfilled.then ->
        wasClosed.should.be.true
