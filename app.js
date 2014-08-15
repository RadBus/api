'use strict';

require('coffee-script/register');
var server = require('./lib/server');
var db = require('./lib/db');

var LOG_PREFIX = 'APP: ';

// capabilities
require('./api').register(server);
require('./web').register(server);

// open the database connection
db.open()
  .then(function () {
    // start
    var port = process.env.PORT || 5001;
    server.listen(port, function () {
      console.log(LOG_PREFIX + "%s, app version %s. Listening at: %s",
        server.name,
        server.appVersion,
        server.url);
    });
  });
