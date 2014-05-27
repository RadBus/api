request = require 'request'
assert = require 'assert'
crypto = require 'crypto'
Q = require 'q'

LOG_PREFIX = 'USER: '

exports.fetch = (authToken) ->
  d = Q.defer()

  googleApiKey = process.env.RADBUS_GOOGLE_API_CLIENT_ID
  salt = process.env.RADBUS_USER_ID_SALT
  if not googleApiKey
    d.reject new Error "Missing env variable: RADBUS_GOOGLE_API_CLIENT_ID"

  else if not salt
    d.reject new Error "Missing env variable: RADBUS_USER_ID_SALT"

  else
    googlePlusFields = ['displayName', 'emails']
    fieldsValue = encodeURIComponent googlePlusFields.join(',')

    options =
      url:
        "https://www.googleapis.com/plus/v1/people/me" +
        "?fields=#{fieldsValue}" +
        "&key=#{googleApiKey}"
      json: true
      headers:
        'Authorization': authToken

    request.get options, (err, response, body) ->
      if err
        d.reject err

      else
        if response.statusCode is 200
          userEmail = body.emails[0].value
          # userId = one-way salted hash of the user's email address
          crypto.pbkdf2 userEmail, salt, 10000, 512, (err, derivedKey) ->
            if err
              d.reject err

            else
              user =
                id: derivedKey.toString('base64')
                displayName: body.displayName

              d.resolve user
        else
          console.log "#{LOG_PREFIX}Failed Google+ profile request:"
          console.log "#{LOG_PREFIX}Status Code = #{response.statusCode}"
          console.log "#{LOG_PREFIX}Body ="
          console.dir body

          d.resolve null

  d.promise
