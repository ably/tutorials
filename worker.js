'use strict';

const Stompit = require('stompit');
const Ably = require('ably');

/* Start the worker that consumes from the STOMP Queue */
exports.start = function(apiKey, filteredChannelName, queueName, host, port, vhost) {
  const appId = apiKey.split('.')[0];
  const username = apiKey.split(':')[0];
  const password = apiKey.split(':')[1];
  const protocolVer = '1.1';
  const useTls = true;
  const queue = appId + ":" + queueName;
  const rest = new Ably.Rest({ key: apiKey });
  const filteredChannel = rest.channels.get(filteredChannelName);

  /* Connect to Ably STOMP queue */
  const connectOptions = {
    'host': host,
    'port': port,
    'ssl': true,
    'connectHeaders':{
      'host': vhost,
      'login': username,
      'passcode': password
    }
  };
  Stompit.connect(connectOptions, function(error, client) {
    if (error) {
      console.error('worker:', 'STOMP client error!', error.message);
      return;
    }

    console.log('worker:', 'Connected to STOMP endpoint', host + ':' + port + '/' + vhost);

    const subscribeHeaders = {
      /* To subscribe to an existing queue, /amq/queue prefix is required */
      'destination': '/amq/queue/' + queue,
      'ack': 'client-individual'
    };
    /* Wait for messages published to the Ably Reactor queue */
    client.subscribe(subscribeHeaders, function(error, message) {
      if (error) {
        console.error('worker:', 'Subscibe error!', error.message);
        return;
      }

      message.readString('utf-8', function(error, body) {
        if (error) {
          console.error('worker:', 'Read message error!', error.message);
          return;
        }

        const decodedEnvelope = JSON.parse(body);
        const messages = Ably.Realtime.Message.fromEncodedArray(decodedEnvelope.messages);
        messages.forEach(function(message) {
          console.log('worker:', 'Received text', message.data, ' - about to ask Neutrino to filter bad words (WHEN IMPLEMENTED)');
        });

        client.ack(message);
      });
    });
  });
};
