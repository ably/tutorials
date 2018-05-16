const path = require('path');
const express = require('express');
const bodyParser = require('body-parser')
const Ably = require('ably');

const restClient = new Ably.Rest({ key: 'YOUR_API_KEY_HERE' });

// See https://expressjs.com/ for help on using Express
const app = express();

// Make the HTML, JavaScript and any other assets publicly accessible
app.use(express.static('public'));

// The user's unique client id is stored in a cookie
app.use(bodyParser());

// Called by the Ably realtime client from the browser side
app.post('/auth', (req, res) => {
  const clientId = req.body.name;

  restClient.auth.createTokenRequest({ clientId, }, (err, tokenRequest) => {
    console.log(`Authorization completed for client "${clientId}"`);
    if(err) {
      res.status(500);
      res.send(err);
    }
    else {
      res.send(tokenRequest);
    }
  });
});

// Ensure that direct requests for a game route are still served by the main index page
app.get('/:gameId', (req, res) => {
  res.sendFile(path.resolve(__dirname, 'public', 'index.html'));
});

// Use the hosting platform's preferred port, if available
const port = process.env.PORT || 3000;
app.listen(port);

console.log(`TicTacToe server is now listening on port ${port}`);