import * as Ably from 'ably';

export function retrieveUserName() {
  return localStorage.getItem('tictactoe:name');
}

export function storeUserName(name) {
  if (!name) {
    debugger;
  }
  localStorage.setItem('tictactoe:name', name);
}

export function enterLobby(onGamePending) {
  const client = getClient();
  const lobbyChannel = getLobby(client);
  const userClientId = getClientId();

  // In the lobby, we use presence only for players who have hosted a game and are waiting for an
  // opponent to join. When an opponent joins a game, the host will leave the lobby.

  lobbyChannel.presence.subscribe(({ action, clientId, data }) => {
    // Ignore the user's own presence events
    if (userClientId === clientId) {
      return;
    }

    switch (action) {
      case 'enter':
      case 'present':
        onGamePending(clientId, data);
        break;

      case 'leave':
        // Omit the second argument to indicate that the game is no longer available
        onGamePending(clientId);
        break;
    }
  });
}

export function enterGame(gameId, onGameStateUpdated) {
  const client = getClient();
  const lobbyChannel = getLobby(client);

  // If we've just arrived from the lobby, we don't need to watch for available games anymore
  lobbyChannel.presence.unsubscribe();

  const gameChannel = client.channels.get(`tictactoe:game:${gameId}`);
  const clientId = getClientId();

  // We'll start with a basic state object and populate it as messages arrive on the game channel
  const gameState = { clientId };

  const updateGameState = createGameMessageHandler(gameState, onGameStateUpdated);

  // Get the game channel history before proceeding, either because we're joining the game as a
  // challenger, or because the page was reloaded
  gameChannel.history({ limit: 1000 }, (error, page) => {
    if (error) {
      // In a real application you'd handle the error properly
      console.error(error);
      return;
    }

    // To save time we'll assume that the history is less than the maximum we specified. In a real
    // application, you'd use the additional `PaginatedResult` methods provided in the `page` object
    // in order to read back through the channel's history, one page at a time.
    // See https://www.ably.io/documentation/realtime/history#paginated-result for details.

    // The messages are in reverse chronological order, so copy the array and reverse it
    const messages = [...page.items];
    messages.reverse();

    // If the history is empty, it means this is a newly-created game. Select which player will be
    // going first. We'll toggle this value whenever the current player makes a move.
    if (messages.length === 0) {
      gameChannel.publish('create', {
        host: clientId,
        currentPlayer: Math.random() < 0.5 ? 'host' : 'opponent'
      });
    }
    else {
      // Replay all the historical messages in order to bring the game back to the correct state
      for (let msg of messages) {
        updateGameState(msg);
      }
    }

    // An undefined host means the first message hasn't even arrived yet
    const isHost = !gameState.host || gameState.host === clientId;

    // We haven't implemented code to allow changes to presence data, or any effects relating to a
    // player leaving the channel, so really we only need to handle 'enter' and 'present' events
    gameChannel.presence.subscribe(['enter', 'present'], msg => {
      if (msg.clientId === clientId) {
        return;
      }

      // Store the other player's name so it can be displayed in the UI
      gameState.otherPlayerName = msg.data.name;
      onGameStateUpdated(gameState);

      // If we're the host and there is no opponent yet, the player who has just joined the game
      // channel will become the opponent. We'll publish this to the game channel so that we know
      // who the other player is, even if they disconnect and reconnect later.
      if (isHost && !gameState.opponent) {
        gameChannel.publish('opponent', { clientId: msg.clientId });
        // gameState.opponent = msg.clientId;

        // Let the host UI know that the opponent has joined and that the game can begin
        // onGameStateUpdated(gameState);
      }
    });

    // Enter the channel and make our name available to the other player
    gameChannel.presence.enter({ name: retrieveUserName() });

    // Monitor game state messages as the game progresses
    gameChannel.subscribe(updateGameState);

    // If we are the host and there is no opponent, use presence to advertise the game in the lobby
    if (isHost && !gameState.opponent) {
      // Use presence in the lobby to expose the game details
      lobbyChannel.presence.enter({ gameId, name: retrieveUserName() });
    }
  });

  return function selectBoardPosition(position) {
    gameChannel.publish('move', { position });
  };
}

const getClient = (() => {
  let client;
  return () => {
    if (!client) {
      const name = retrieveUserName();
      client = new Ably.Realtime({
        authUrl: '/auth',
        authMethod: 'POST',
        authParams: { name }
      });
    }
    return client;
  };
})();

function getClientId() {
  // To keep things simple in this tutorial, we're just using the user's name for the client id
  return retrieveUserName();
}

function getLobby(client) {
  return client.channels.get('tictactoe:lobby');
}

function createGameMessageHandler(gameState, onGameStateUpdated) {
  return function updateGameState(message) {
    const { clientId, data } = message;
    switch (message.name) {
      case 'create':
        if (gameState.currentPlayer) {
          console.warn('The game has already been initialized; disregarding "create" message');
          return;
        }
        gameState.host = clientId;
        gameState.status = 'waiting';
        gameState.board = [0, 0, 0, 0, 0, 0, 0, 0, 0];
        gameState.remaining = 9;
        gameState.currentPlayer = data.currentPlayer;
        break;

      case 'opponent':
        if (gameState.opponent) {
          console.warn('The game already has an opponent; disregarding "opponent" message');
          return;
        }
        gameState.status = 'in-progress';
        gameState.opponent = data.clientId;
        break;

      case 'move':
        // Normally we'd have a server validate and apply the moves, but for simplicity we're doing
        // it in the browser.
        const { position } = data;
        const { currentPlayer, board } = gameState;
        const currentPlayerId = gameState[currentPlayer]; // currentPlayer is 'host' or 'opponent'
        const isGameInProgress = gameState.status === 'in-progress';
        const isBoardPositionAssigned = board[position] !== 0;

        if (!isGameInProgress || isBoardPositionAssigned || clientId !== currentPlayerId) {
          console.warn('Disregarding invalid game move message');
          return;
        }

        // Now that we know that this move is valid, apply it to the array of board positions
        board[position] = currentPlayer === 'host' ? 1 : 2;

        // Get an array of the three winning positions, or false if the game is not yet won
        const winCondition = checkForWinCondition(board, position);

        if (winCondition) {
          // The current player is the winner
          gameState.status = 'win';
          gameState.winCondition = winCondition;
        }
        else if (--gameState.remaining === 0) {
          // All board positions are full - nobody wins
          gameState.status = 'draw';
        }
        else {
          // It's now the other player's turn
          gameState.currentPlayer = currentPlayer === 'host' ? 'opponent' : 'host';
        }
        break;
    }

    // Dispatch the game state back to the UI so it can be rendered
    onGameStateUpdated(gameState);
  };
}

function checkForWinCondition(board, latestPosition) {
  const value = board[latestPosition];

  const checkPositions = (a, b, c) =>
    board[a] === value &&
    board[b] === value &&
    board[c] === value &&
    [a, b, c];

  // To keep it simple, and because the board is small, a simple brute force check is fine

  return checkPositions(0, 1, 2) ||
    checkPositions(3, 4, 5) ||
    checkPositions(6, 7, 8) ||
    checkPositions(0, 3, 6) ||
    checkPositions(1, 4, 7) ||
    checkPositions(2, 5, 8) ||
    checkPositions(0, 4, 8) ||
    checkPositions(2, 4, 6);
}
