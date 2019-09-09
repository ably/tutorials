const Ably = require('ably');
const constants = require('./constants');

/* Instance the Ably library */
const realtime = new Ably.Realtime({key: constants.API_KEY});