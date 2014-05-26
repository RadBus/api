Q = require 'q'

exports.fetch = (authToken) ->
  user =
    if authToken is 'foo-token'
      id: 'foo'
      displayName: 'Foo User'
    else null

  Q user
