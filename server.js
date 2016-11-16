const Ably = require("ably");

const ApiKey = "I2E_JQ.79AfrA:sw2y9zarxwl0Lw5a"; /* Add your API key here */
if (ApiKey.indexOf("INSERT") === 0) { throw("Cannot run without an API key. Add your key to example.js"); }

/* Instance the Ably REST server library */
var rest = new Ably.Rest({ key: ApiKey });

/* Start the Express.js web server */
const express = require('express'),
      app = express();

/* Server static content from the root path to keep things simple */
app.use('/', express.static(__dirname));

/* Issue token requests to clients sending a request
   to the /auth endpoint */
app.get('/auth', function (req, res) {
  var tokenParams = {}; /* For now we'll use all token defaults */
  rest.auth.createTokenRequest(tokenParams, function(err, tokenRequest) {
    if (err) {
      res.status(500).send('Error requesting token: ' + JSON.stringify(err));
    } else {
      res.setHeader('Content-Type', 'application/json');
      res.send(JSON.stringify(tokenRequest));
    }
  });
});

app.listen(3000, function () {
  console.log('Web server listening on port 3000');
});
