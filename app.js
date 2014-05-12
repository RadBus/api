require('coffee-script/register');
var thisPackage = require('./package');
var server = require('./lib/server');
var db = require('./lib/db');

// capabilities
require('./api').register(server);

// open the database connection
db.open()
  .then(function () {
    // start
    var port = process.env.PORT || 5001;
    server.listen(port, function () {
      console.log("%s, version %s. Listening at: %s",
        server.name,
        thisPackage.version,
        server.url);
    });
  });
