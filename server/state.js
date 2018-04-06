const generate = require('nanoid/generate');
const Ably = require('ably');

// Be sure to update this code with your own API key!
const ablyOptions = { key: 'API_KEY_HERE' };

// The realtime client allows the server to update game state immediately when players make a move
const realtimeClient = new Ably.Realtime(ablyOptions);

// The REST client can be used when making once-off requests to unmonitored channels
const restClient = new Ably.Rest(ablyOptions);

// The server monitors the users channel in order to respond to player activity and update game state
const usersChannel = realtimeClient.channels.get('tictactoe:users');

usersChannel.subscribe(msg => {
  if (msg.name !== 'move') return;

  const { gameId, clientId, position } = msg.data || {};
  if(!gameId) return;

  const gameChannel = restClient.channels.get(`tictactoe:game:${gameId}`);

  // Get the last state message that was posted to the referenced game channel
  gameChannel.history({ limit: 1 }, (err, page) => {
    if(err) return console.log(err);

    // If the game has expired, ignore the message
    if(page.items.length === 0) return;

    let { data: { players, currentPlayer, board, remaining, status } } = page.items[0];

    // Seeing as the server is mediating, cheating is not an issue
    const isValidMove =
      status === 'in-progress' && // Make sure the game has not ended
      players[currentPlayer] === clientId && // Make sure that the current player is not taking an extra turn
      board[position] === 0; // Ensure that the specified board position has not already been set

    // Ignore cheaters and glitches
    if(!isValidMove) return;

    // Update the board state: 0 is unset, 1 is [X], 2 is [O]
    board[position] = currentPlayer + 1;

    // Get an array of the three winning positions, or false if the game is not yet won
    const winCondition = checkForWinCondition(board, position);

    if(winCondition) {
      status = 'win';
    }
    else if(--remaining === 0) {
      status = 'draw';
    }
    else {
      currentPlayer = currentPlayer === 0 ? 1 : 0;
    }

    const newState = {
      players,
      currentPlayer,
      board,
      remaining,
      status,
      winCondition
    };

    // Players are subscribed to the game channel, but only the server can publish game state messages
    gameChannel.publish('state', newState, err => {
      console.log(`Client ${clientId} assigned position ${position} of game ${gameId} (updated status: ${status})`);
      if(err) return console.log(err);
    });
  });
});

exports.auth = function auth(clientId, gameId, callback) {
  if(gameId) {
    // A game id is provided when the player is viewing a game route in the client application
    checkGameAccess(clientId, gameId, callback);
  }
  else {
    // Provide general permissions when the player is not on the game page
    completeAuth(clientId, {}, callback);
  }
}

exports.createGame = function(clientId, callback) {
  const gameId = generate('0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ', 12);
  const gameChannelId = `tictactoe:game:${gameId}`;
  const gameChannel = restClient.channels.get(gameChannelId);

  gameChannel.publish('player1', { clientId }, err => {
    console.log(`Game ${gameId} created by client ${clientId}`);
    callback(err, { gameId, channel: gameChannelId });
  });
}

function checkGameAccess(clientId, gameId, callback) {
  const channelName = `tictactoe:game:${gameId}`;
  const gameChannel = restClient.channels.get(channelName);

  gameChannel.history({ limit: 2, direction: 'forwards' }, (err, result) => {
    if(err) return callback(err);

    const { items } = result;
    if(items.length === 0) {
      // game no longer exists; omit game from access
      return completeAuth(clientId, {}, callback);
    }

    // The first two messages in the game channel identify player 1 and 2, respectively
    const player1 = items[0].data.clientId;
    const isAwaitingPlayer2 = items.length === 1;
    const player2 = isAwaitingPlayer2 ? void 0 : items[1].data.clientId;

    // Other people may watch the game, but cannot interact with it
    const isPlayer = clientId === player1 || clientId === player2;

    // Grant the client read-only access to the game channel
    const access = { [channelName]: ['subscribe', 'history', 'presence'] };

    // The second unique client to access the game will become player 2
    if(!isPlayer && isAwaitingPlayer2) {
      // Post a message to the channel identifying player 2
      return gameChannel.publish('player2', { clientId }, err => {
        if(err) return callback(err);

        // Now that we have identified player 2, publish the initial game state
        const initialState = {
          players: [player1, clientId],
          currentPlayer: gameId.charCodeAt(0) & 1,
          board: [0,0,0,0,0,0,0,0,0],
          remaining: 9,
          status: 'in-progress'
        };

        gameChannel.publish('state', initialState, err => {
          if(err) return callback(err);
          console.log(`Player 2 has joined game ${gameId}`);
          completeAuth(clientId, access, callback);
        });
      });
    }

    // Permission to view the game is granted irrespective of what happened above
    completeAuth(clientId, access, callback);
  });
}

function completeAuth(clientId, access, callback) {
  // Generate a token request locally, signed with the user's API key
  restClient.auth.createTokenRequest({
    clientId,
    capability: Object.assign(access, {
      ['tictactoe:game']: ['subscribe', 'history', 'presence'],
      ['tictactoe:users']: ['publish']
    })
  }, (err, tokenRequest) => {
    console.log(`Authorization completed for client ${clientId}`);
    callback(err, err ? null : tokenRequest);
  });
}

function checkForWinCondition(board, position) {
  const value = board[position];

  const checkPositions = (a, b, c) =>
    board[a] === value &&
    board[b] === value &&
    board[c] === value &&
    [a, b, c];

  // To keep it simple, and because the board is small, a simple brute force check is fine:
  return checkPositions(0, 1, 2) ||
    checkPositions(3, 4, 5) ||
    checkPositions(6, 7, 8) ||
    checkPositions(0, 3, 6) ||
    checkPositions(1, 4, 7) ||
    checkPositions(2, 5, 8) ||
    checkPositions(0, 4, 8) ||
    checkPositions(2, 4, 6);
}
