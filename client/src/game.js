import * as Ably from 'ably';

const getAuthOptions = gameId => ({ authUrl: `/api/auth?gameId=${gameId || ''}` });

// A simple abstraction to convert Node.js-style callbacks to promises
const createPromise = callback => {
  return new Promise((resolve, reject) => {
    callback((err, value) => err ? reject(err) : resolve(value));
  });
}

export default class GameState {
  static create(gameId) {
    return new GameState(gameId);
  }

  constructor(gameId) {
    this.gameId = gameId;
    this.client = new Ably.Realtime(getAuthOptions(gameId));
    this.usersChannel = this.client.channels.get('tictactoe:users');
    this.gameChannel = void 0;
  }

  get clientId() {
    return this.client.auth.clientId;
  }

  get userName() {
    return localStorage.getItem('tictactoe:name') || '';
  }

  setUserName(name) {
    localStorage.setItem('tictactoe:name', name);
    return !this.gameChannel ? Promise.resolve() : createPromise(callback => {
      this.gameChannel.presence.update({ name }, callback);
    });
  }

  newGame() {
    // Ask the server to create a new game
    return fetch('/api/new-game', { credentials: 'same-origin' })
      .then(res => res.json())
      .then(game => createPromise(callback => {
        this.gameId = game.gameId;
        const authOptions = getAuthOptions(game.gameId);
        // Now that we have a game id, update the user's authorization token to grant access to
        // the newly-created game channel
        this.client.auth.authorize(null, authOptions, callback);
      })
      .then(() => game)); // return the details to the app view
  }

  enterGame(gameId, onMessage) {
    const { client } = this;
    const gameChannel = this.gameChannel = client.channels.get(`tictactoe:game:${gameId}`);
    // Temporarily store any messages received while setting things up
    const messages = [];
    // As above, but for presence events
    const presenceEvents = [];
    // And again, as above, in case there are multiple pages of history
    const history = [];
    let ready = false;

    return new Promise((resolve, reject) => {
      function readHistory(err, resultPage) {
        if(err) return reject(err);

        history.push(...resultPage.items);
        if(resultPage.hasNext()) {
          resultPage.next(readHistory);
        }
        else {
          // If there is no history, the initial message published by the server problem hasn't yet
          // been synchronized to Ably's internal persistence stores. If this is the case, we'll
          // wait a few seconds and then try again.
          if (history.length === 0 && messages.length === 0) {
            setTimeout(() => {
              // Specify start = 0, to ensure that subsequent attempts start from the beginning
              gameChannel.history({ start: 0, untilAttach: true }, readHistory);
            }, 3000);
            return;
          }
          resolve();

          // History is received in reverse chronological order, so reverse the array accordingly
          history.reverse();
          for(let item of history) {
            // Emit each item of history first
            onMessage(item);
          }

          for(let item of messages) {
            // Next emit any messages we received while waiting for historical messages
            onMessage(item);
          }

          for(let item of presenceEvents) {
            // Finish up with any presence events received while waiting for history to resolve
            onMessage(item);
          }

          // Clear the arrays so they don't waste resources now that we don't need them
          messages.length = 0;
          presenceEvents.length = 0;

          // Ensure that any future events are emitted directly to the game
          ready = true;
        }
      }

      // Attach the channel first in order to create a clear marker between future and historical events
      const messageHandler = msg => {
        if(ready) {
          onMessage(msg);
        }
        else {
          messages.push(msg);
        }
      };

      const presenceHandler = event => {
        if(ready) {
          onMessage(event);
        }
        else {
          presenceEvents.push(event);
        }
      };

      // Subscribe immediately in order to start collecting future messages
      gameChannel.subscribe(messageHandler);

      // Do the same for presence events
      gameChannel.presence.subscribe(presenceHandler);

      // Register our presence in the game channel
      gameChannel.presence.enter({ name: this.userName }, err => {
        if(err) return reject(err);

        // Finish up by initiating history retrieval up to the point where the channel was attached
        gameChannel.history({ start: 0, untilAttach: true }, readHistory);
      })
    });
  }

  exitGame() {
    // When we create a new game, we need to make sure we stop listening to the old channel before
    // we upgrade the authorization token to grant access to the new game channel
    this.gameChannel.detach();
    this.gameChannel = void 0;
  }

  selectBoardPosition(position) {
    const { gameId, clientId } = this;
    const move = { gameId, clientId, position };
    // Publish our move to the users channel. The server monitors this channel and responds by
    // posting updated game state messages to the game channel.
    return createPromise(callback => this.usersChannel.publish('move', move, callback));
  }
}
