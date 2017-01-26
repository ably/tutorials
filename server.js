const Ably = require('ably');
const Express = require('express');
const ServerPort = 3000;
const worker = require('./worker');

const ApiKey = process.env.ABLY_API_KEY || 'INSERT-YOUR-API-KEY-HERE'; /* Add your API key here */
if (ApiKey.indexOf('INSERT') === 0) { throw('Cannot run without an Ably API key. Add your key to server.js'); }

const NeutrinoUserId = process.env.NEUTRINO_USER_ID || 'INSERT-YOUR-NEUTRINO-USER-ID-HERE'; /* Add your Neutrino User ID here */
if (NeutrinoUserId.indexOf('INSERT') === 0) { throw('Cannot run without a Neutrino User ID. Add your user ID to server.js'); }
const NeutrinoApiKey = process.env.NEUTRINO_API_KEY || 'INSERT-YOUR-NEUTRINO-API-KEY-HERE'; /* Add your Neutrino API Key here */
if (NeutrinoApiKey.indexOf('INSERT') === 0) { throw('Cannot run without a Neutrino API key. Add your key to server.js'); }

/* Instance the Ably library */
const rest = new Ably.Rest({ key: ApiKey });

/* Start a web server */
var app = Express();

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

worker.start(ApiKey, NeutrinoUserId, NeutrinoApiKey, 'neutrino:filtered', 'neutrino', 'us-east-1-a-queue.ably.io', 61614, 'shared');

console.log('Open the Neutrino demo in your browser: https://localhost:' + ServerPort + '/');
