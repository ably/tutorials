'use strict';

const amqp = require('amqplib/callback_api');
const Ably = require('ably');
const request = require('request');
const querystring = require("querystring");
const WolframEndpoint = 'http://api.wolframalpha.com/v1/result';

/* Send question over HTTP to Wolfram to find the answer */
function getAnswerAndPublish(ablyChannel, wolframUrl, question) {
  console.log('worker:', 'Received question', question, ' - about to ask Wolfram');
  var timeNow = Date.now();
  request(wolframUrl, function (error, response, body) {
    var timePassed = Date.now() - timeNow;
    if (!error && response.statusCode == 200) {
      publishAnswer(ablyChannel, question, body, timePassed)
    } else {
      if (body) {
        publishAnswer(ablyChannel, question, "Wolfram couldn't compute: " + body, timePassed);
      } else {
        publishAnswer(ablyChannel, question, "Wolfram error: " + JSON.stringify(error), timePassed);
      }
    }
  });
}

function publishAnswer(ablyChannel, question, answer, wolframTime) {
  ablyChannel.publish('answer', { question: question, answer: answer, wolframTime: wolframTime }, function(err) {
    if (err) {
      console.error('worker:', 'Failed to publish question', question, ' - err:', JSON.stringify(err));
    }
  })
}

/* Start the worker that consumes from the AMQP QUEUE */
exports.start = function(apiKey, wolframApiKey, answersChannelName, queueName, queueEndpoint) {
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
          var question = message.data;
          var url = WolframEndpoint + '?' + querystring.stringify({ appid: wolframApiKey, i: question});
          getAnswerAndPublish(answersChannel, url, question);
        });

        /* Remove message from queue */
        ch.ack(item);
      });
    });

    conn.on('error', function(err) { console.error('worker:', 'Connection error!', err); });
  });
};
