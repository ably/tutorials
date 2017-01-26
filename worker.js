'use strict';

const amqp = require('amqplib/callback_api');
const Ably = require('ably');
const request = require('request');
const querystring = require("querystring");
const NeutrinoEndpoint = 'https://neutrinoapi.com/bad-word-filter';

/* Send text over HTTP to Neutrino to filter the profanities */
function filterTextAndPublish(ablyChannel, neutrinoUserId, neutrinoApiKey, text) {
  var url = NeutrinoEndpoint + '?' + querystring.stringify({
    "user-id": neutrinoUserId,
    "api-key": neutrinoApiKey,
    "content": text,
    "censor-character": "*"
  });
  var timeNow = Date.now();
  request(url, function (error, response, body) {
    var timePassed = Date.now() - timeNow;
    if (!error && response.statusCode == 200) {
      publishAnswer(ablyChannel, text, JSON.parse(body)["censored-content"], timePassed);
    } else {
      if (body) {
        publishAnswer(ablyChannel, text, "Neutrino couldn't compute: " + body, timePassed);
      } else {
        publishAnswer(ablyChannel, text, "Neutrino error: " + JSON.stringify(error), timePassed);
      }
    }
  });
}

function publishAnswer(ablyChannel, rawText, filteredText, neutrinoTime) {
  ablyChannel.publish('text', { filteredText: filteredText, neutrinoTime: neutrinoTime }, function(err) {
    if (err) {
      console.error('worker:', 'Failed to publish text', rawText, ' - err:', JSON.stringify(err));
    }
  })
}

/* Start the worker that consumes from the AMQP Queue */
exports.start = function(apiKey, neutrinoUserId, neutrinoApiKey, filteredChannelName, queueName, queueEndpoint) {
  const appId = apiKey.split('.')[0];
  const queue = appId + ":" + queueName;
  const endpoint = queueEndpoint;
  const url = 'amqps://' + apiKey + '@' + endpoint;
  const rest = new Ably.Rest({ key: apiKey });
  const filteredChannel = rest.channels.get(filteredChannelName);

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
          console.log('worker:', 'Received text', message.data, '- about to ask Neutrino to filter bad words');
          filterTextAndPublish(filteredChannel, neutrinoUserId, neutrinoApiKey, message.data);
        });

        /* Remove message from queue */
        ch.ack(item);
      });
    });

    conn.on('error', function(err) { console.error('worker:', 'Connection error!', err); });
  });
};
