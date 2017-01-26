'use strict';

const Stompit = require('stompit');
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
  });
}

/* Start the worker that consumes from the STOMP Queue */
exports.start = function(apiKey, neutrinoUserId, neutrinoApiKey, filteredChannelName, queueName, host, port, vhost) {
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
          console.log('worker:', 'Received text', message.data, '- about to ask Neutrino to filter bad words');
          filterTextAndPublish(filteredChannel, neutrinoUserId, neutrinoApiKey, message.data);
        });

        client.ack(message);
      });
    });
  });
};