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
  var tokenParams;
  /* Check if the user wants to log in */
  if (req.query['username']) {
    /* Issue a token request with pub & sub permissions on all channels +
       configure the token with an identity */
    tokenParams = {
      'capability': { '*': ['publish', 'subscribe'] },
      'clientId': req.cookies.username
    };
  } else {
    /* Issue a token with subscribe privileges restricted to one channel
       and configure the token without an identity (anonymous) */
    tokenParams = {
      'capability': { 'notifications': ['subscribe'] }
    };
  }
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
