const Ably = require("ably");

const ApiKey = "I2E_JQ.79AfrA:sw2y9zarxwl0Lw5a"; /* Add your API key here */
if (ApiKey.indexOf("INSERT") === 0) { throw("Cannot run without an API key. Add your key to example.js"); }

/* Instance the Ably REST server library */
var rest = new Ably.Rest({ key: ApiKey });

/* Start the Express.js web server */
const express = require('express'),
      app = express();

app.get('/', function (req, res) {
  res.send('Hello, I am a very simple server');
});

app.listen(3000, function () {
  console.log('Web server listening on port 3000');
});
