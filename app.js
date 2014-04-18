require('coffee-script/register');
var thisPackage = require('./package');
var server = require('./server');

// capabilities
require('./api').register(server);
require('./web').register(server);

// start
var port = process.env.PORT || 5001;
server.listen(port, function () {
  console.log("%s, version %s. Listening at: %s",
    server.name,
    thisPackage.version,
    server.url);
});
