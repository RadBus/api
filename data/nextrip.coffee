request = require 'request'
Q = require 'q'

exports.callApi = (url, state) ->
  options =
    url: "http://svc.metrotransit.org/NexTrip/#{url}"
    json: true

  d = Q.defer()
  request.get options, (err, response, body) ->
    if err
      d.reject err
    else
      d.resolve
        json: body
        state: state
  d.promise
