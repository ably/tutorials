const Ably = require('ably');
const Express = require('express');
const ServerPort = 3000;

const ApiKey = 'INSERT-YOUR-API-KEY-HERE'; /* Add your API key here */
if (ApiKey.indexOf('INSERT') === 0) { throw('Cannot run without an API key. Add your key to example.js'); }

/* Instance the Ably library */
var rest = new Ably.Rest({ key: ApiKey });

/* Start a web server */
var express = require('express');
var app = express();

/* Server static HTML files from /public folder */
app.use(express.static('public'));
app.listen(3000);

console.log('Web server listening on port', ServerPort);
