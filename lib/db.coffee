Q = require 'q'
mongoose = require 'mongoose'

# Open the default database connection
exports.open = ->
  d = Q.defer()

  # When successfully connected
  mongoose.connection.on 'connected', ->
    connection = mongoose.connection

    renderHost = (container) -> "#{container.host}:#{container.port}"
    hosts = if connection.replica
        # multiple hosts
        connection.hosts.map(renderHost).join ','
      else
        renderHost(connection)
    ssl = if connection.db.serverConfig.ssl then 'SSL' else 'No SSL'

    console.log "Default database connection opened to: #{hosts}/#{connection.name} (#{ssl})"

    d.resolve()

  # If the connection throws an error
  mongoose.connection.on 'error', (err) ->
    console.error "Database default connection error: #{err}"
    d.reject err

  # If the Node process ends, close the Mongoose connection
  onProcessTermination = ->
    console.log "Closing default database connection due to app termination..."
    exports.close()
      .then ->
        process.exit 0

  process.on 'SIGINT', onProcessTermination
  process.on 'SIGTERM', onProcessTermination

  # Perform the connect
  uri = process.env.MONGOHQ_URL
  console.log "Opening default database connection..."
  mongoose.connect uri

  d.promise

# Close the default database connection
exports.close = ->
  d = Q.defer()

  # When the connection is disconnected
  mongoose.connection.on 'disconnected', () ->
    console.log "Database default connection closed"
    d.resolve()

  # Perform the close
  mongoose.connection.close()

  d.promise
