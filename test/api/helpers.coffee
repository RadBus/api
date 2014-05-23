chai = require 'chai'
chai.use require 'chai-as-promised'
should = chai.should()
proxyquire = require 'proxyquire'

exports.buildServer = (resourceModulePath, stubs) ->
  # stub server dependencies
  # (none)

  # ensure server is a new instance each time
  proxyquire.noPreserveCache()
  server = proxyquire '../../lib/server', {}
  # server = require '../../lib/server'
  proxyquire.preserveCache()

  # load resource module and register with server
  resource =
    if stubs
      proxyquire(resourceModulePath, stubs)
    else
      require resourceModulePath

  resource.register server, ''

  server
