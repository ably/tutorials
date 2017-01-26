'use strict';

const amqp = require('amqplib/callback_api');
const Ably = require('ably');

/* Start the worker that consumes from the AMQP QUEUE */
exports.start = function(apiKey, answersChannelName, queueName, queueEndpoint) {
  const appId = apiKey.split('.')[0];
  const queue = appId + ":" + queueName;
  const endpoint = queueEndpoint;
  const url = 'amqps://' + apiKey + '@' + endpoint;
  const rest = new Ably.Rest({ key: apiKey });
  const answersChannel = rest.channels.get(answersChannelName);

  /* Connect to Ably queue */
  amqp.connect(url, (err, conn) => {
    if (err) {
      console.error('worker:', 'Queue error!', err);
      return;
    }
    console.log('worker:', 'Connected to AMQP endpoint', endpoint);

    /* Create a communication channel */
    conn.createChannel((err, ch) => {
      if (err) {
        console.error('worker:', 'Queue error!', err);
        return;
      }
      console.log('worker:', 'Waiting for messages');

      /* Wait for messages published to the Ably Reactor queue */
      ch.consume(queue, (item) => {
        const decodedEnvelope = JSON.parse(item.content);

        const messages = Ably.Realtime.Message.fromEncodedArray(decodedEnvelope.messages);
        messages.forEach(function(message) {
          console.log('worker:', 'Received question', message.data, ' - about to ask Wolfram');
          answersChannel.publish('answer', 'Placeholder until Wolfram connected', function(err) {
            if (err) {
              console.error('worker:', 'Failed to publish question', message.data, ' - err:', JSON.stringify(err));
            }
          })
        });

        /* Remove message from queue */
        ch.ack(item);
      });
    });

    conn.on('error', function(err) { console.error('worker:', 'Connection error!', err); });
  });
};
