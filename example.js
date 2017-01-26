const Ably = require('ably');
const Express = require('express');
const ServerPort = 3000;
const worker = require('./worker');

const ApiKey = 'INSERT-YOUR-API-KEY-HERE'; /* Add your API key here */
if (ApiKey.indexOf('INSERT') === 0) { throw('Cannot run without an API key. Add your key to example.js'); }

/* Instance the Ably library */
var rest = new Ably.Rest({ key: ApiKey });

/* Start a web server */
var express = require('express');
var app = express();

/* Issue token requests to browser clients sending a request to the /auth endpoint */
app.get('/auth', function (req, res) {
  rest.auth.createTokenRequest(function(err, tokenRequest) {
    if (err) {
      res.status(500).send('Error requesting token: ' + JSON.stringify(err));
    } else {
      res.setHeader('Content-Type', 'application/json');
      res.send(JSON.stringify(tokenRequest));
    }
  });
});

/* Server static HTML files from /public folder */
app.use(express.static('public'));
app.listen(3000);

worker.start(ApiKey, 'wolfram:answers', 'wolfram', 'us-east-1-a-queue.ably.io:5671/shared');

console.log('Open the Wolfram demo in your browser: https://localhost:' + ServerPort + '/');
