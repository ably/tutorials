const Ably = require('ably');
const Express = require('express');
const ServerPort = 3000;
const worker = require('./worker');

const ApiKey = 'INSERT-YOUR-API-KEY-HERE'; /* Add your API key here */
if (ApiKey.indexOf('INSERT') === 0) { throw('Cannot run without an Ably API key. Add your key to server.js'); }

const WolframAppId = 'INSERT-YOUR-WOLFRAM-API-KEY-HERE'; /* Add your Wolfram AppID here */
if (WolframAppId.indexOf('INSERT') === 0) { throw('Cannot run without a Wolfram API key. Add your key to server.js'); }

/* Instance the Ably library */
const rest = new Ably.Rest({ key: ApiKey });

/* Start a web server */
const app = Express();

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
app.use(Express.static('public'));
app.listen(3000);

worker.start(ApiKey, WolframAppId, 'wolfram:answers', 'wolfram', 'us-east-1-a-queue.ably.io:5671/shared');

console.log('Open the Wolfram demo in your browser: https://localhost:' + ServerPort + '/');
