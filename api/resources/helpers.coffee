exports.parseMetroTransitStop = (stop) ->
  matches = /^(\d+):(.*)$/.exec stop
  if matches
    id: matches[1],
    description: matches[2]
