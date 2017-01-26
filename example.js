const Ably = require('ably');
const Express = require('express');
const ServerPort = process.env.PORT || 3000;
const worker = require('./worker');

const ApiKey = process.env.ABLY_API_KEY || 'INSERT-YOUR-API-KEY-HERE'; /* Add your Ably API key here */
if (ApiKey.indexOf('INSERT') === 0) { throw('Cannot run without an Ably API key. Add your key to example.js'); }

const WolframAppId = process.env.WOLFRAM_APP_ID || 'INSERT-YOUR-WOLFRAM-API-KEY-HERE'; /* Add your Wolfram AppID here */
if (WolframAppId.indexOf('INSERT') === 0) { console.warn('Cannot run without a Wolfram AppID. Add your AppID to example.js'); }

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
if (WolframAppId.indexOf('INSERT') === 0) {
  app.get('/', function (req, res) {
    res.status(500).send('WolframAppId is not set. You need to configure an environment variable WOLFRAM_APP_ID');
  });
}

app.use(express.static('public'));
app.listen(ServerPort);

worker.start(ApiKey, WolframAppId, 'wolfram:answers', 'wolfram', 'us-east-1-a-queue.ably.io:5671/shared');

console.log('Open the Wolfram demo in your browser: https://localhost:' + ServerPort + '/');
