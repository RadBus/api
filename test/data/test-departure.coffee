# coffeelint: disable=max_line_length

chai = require 'chai'
chai.use require 'chai-as-promised'
should = chai.should()
proxyquire = require 'proxyquire'
Q = require 'q'

# stub dependencies
nextrip = {}

# target library under test
target = proxyquire '../../data/departure',
  './nextrip': nextrip

describe "data/departure", ->
  describe "#fetch", ->
    beforeEach ->
      process.env.RADBUS_TIMEZONE = 'America/Chicago'

      nextrip.callApi = (url, state) ->
        Q
          state: state
          json:
            if url is '123/2/STP1'
              [
                {
                  DepartureTime: '/Date(1400874180000-0500)/'
                  Route: '123'
                  Terminal: 'A'
                  VehicleLatitude: -100
                  VehicleLongitude: 100
                },
                {
                  DepartureTime: '/Date(1400875980000-0500)/'
                  Route: '123'
                  Gate: 'X'
                  VehicleLatitude: 0
                  VehicleLongitude: 0
                }
              ]
            else []

      afterEach ->
        delete process.env.RADBUS_TIMEZONE

    it "should return nothing if the specified route/direction/stop has no data", ->
      target.fetch '123', '2', 'OTHER-STOP'
        .should.eventually.be.fulfilled
          .and.be.an('array').that.has.length 0

    it "should return the expected route detail if it exists", ->
      target.fetch '123', '2', 'STP1'
        .should.eventually.be.fulfilled
          .and.be.an('array').that.has.length(2)
          .and.then (departures) ->
            departure = departures[0]
            departure.should.have.deep.property 'time'
            departure.time.format().should.equal '2014-05-23T14:43:00-05:00'
            departure.should.have.property 'routeId', '123'
            departure.should.have.property 'terminal', 'A'
            departure.should.not.have.property 'gate'
            departure.should.have.deep.property 'location.lat', -100
            departure.should.have.deep.property 'location.long', 100

            departure = departures[1]
            departure.should.have.property 'time'
            departure.time.format().should.equal '2014-05-23T15:13:00-05:00'
            departure.should.have.property 'routeId', '123'
            departure.should.not.have.property 'terminal'
            departure.should.have.property 'gate', 'X'
            departure.should.not.have.property 'location'
