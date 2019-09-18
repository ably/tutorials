const Ably = require('ably');
const constants = require('./constants');

/* Instance the Ably library */
const realtime = new Ably.Realtime({key: constants.API_KEY});
const channelOpts = {cipher: {key: constants.SECRET}};
const subChannel = realtime.channels.get('encrypted:messages', channelOpts);

console.log('Retrieving encrypted message');

/* Subscribe to messages */
subChannel.subscribe(console.log);
