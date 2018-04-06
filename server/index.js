const path = require('path');
const express = require('express');
const cookieParser = require('cookie-parser')
const nanoid = require('nanoid');
const generate = require('nanoid/generate');
const Ably = require('ably');
const state = require('./state');

// See https://expressjs.com/ for help on using Express
const app = express();

// Make the HTML, JavaScript and any other assets publicly accessible
app.use(express.static('public'));

// The user's unique client id is stored in a cookie
app.use(cookieParser());

// Read or generate a client id for the user, and check which game is being accessed (if any)
app.use((req, res, next) => {
  const cookieKey = 'tictactoe-clientId';
  let clientId = req.cookies[cookieKey];

  // Generate a new id for the player if this is the first time they've visited the site
  if (!clientId) clientId = nanoid();

  // Always write the clientId cookie to keep the expiry date fresh
  const expires = new Date();
  expires.setFullYear(expires.getFullYear() + 1);
  res.cookie(cookieKey, clientId, { expires });

  // Make values available to routes and other middleware
  req.clientId = clientId;
  req.gameId = req.query.gameId;
  next();
});

// Called by the Ably realtime client from the browser side
app.get('/api/auth', (req, res) => {
  state.auth(req.clientId, req.gameId, function(err, state) {
    if(err) {
      res.status(500);
      res.send(err);
    }
    else {
      res.send(state);
    }
  });
});

// Called when the user clicks the red "Create Game" button
app.get('/api/new-game', (req, res) => {
  state.createGame(req.clientId, function(err, state) {
    if(err) {
      res.status(500);
      res.send(err);
    }
    else {
      res.send(state);
    }
  });
});

// Ensure that direct requests for a game route are still served by the main index page
app.get('/:gameId', (req, res) => {
  res.sendFile(path.resolve(__dirname, 'public', 'index.html'));
});

const port = 3000;
app.listen(port);

console.log(`TicTacToe server is now listening on port ${port}`);