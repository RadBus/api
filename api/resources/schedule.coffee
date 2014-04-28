restify = require 'restify'

exports.register = (server, baseRoute) ->
  server.get "#{baseRoute}/schedule", get
  server.post "#{baseRoute}/schedule", post

responseType = '404'

get = (req, res, next) ->
  if not req.header 'Authorization'
    res.send new restify.InvalidCredentialsError "Not so fast."

  else
    switch responseType
      when '404'
        res.send new restify.ResourceNotFoundError "No schedules defined."

        responseType = 'empty'

      when 'empty'
        res.send {}

        responseType = 'data'

      when 'data'
        res.send
          routes:
            261:
              am:
                direction: 1
                stops: ['GRCH']
              pm:
                direction: 4
                stops: ['112A']
            263:
              am:
                direction: 1
                stops: ['RCPR']
              pm:
                direction: 4
                stops: ['112A']
            264:
              am:
                direction: 1
                stops: ['CCPR']
              pm:
                direction: 4
                stops: ['112A']
            270:
              am:
                direction: 3
                stops: ['MPWD', '61%24C', 'RCPR']
              pm:
                direction: 2
                stops: ['112A']

        responseType = '404'

  next()

post = (req, res, next) ->
  if not req.header 'Authorization'
    res.send new restify.InvalidCredentialsError "Not so fast."

  else
    res.send 201

  next()
