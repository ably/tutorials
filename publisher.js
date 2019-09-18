const Ably = require('ably');
const constants = require('./constants');

/* Instance the Ably library */
const realtime = new Ably.Realtime({key: constants.API_KEY});
const channelOpts = {cipher: {key: constants.SECRET}};
const pubChannel = realtime.channels.get('encrypted:messages', channelOpts);

console.log('Publishing encrypted message');

/* Publish encrypted messages */
pubChannel.publish('unencrypted', 'an encrypted message');