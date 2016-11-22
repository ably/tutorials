const Ably = require("ably");
const Pubnub = require("pubnub");

const API_KEY = "INSERT-YOUR-API-KEY-HERE"; // Add your API key here
if (API_KEY.indexOf("INSERT") === 0) {
  throw("Cannot run without an API key. Add your key to example.js");
}
var channelName = 'some_channel';

/* ABLY CLIENT LIB */
/* Instance the Ably library */
var ably = new Ably.Realtime(API_KEY);

/* Subscribe to the 'some_channel' channel with the Ably client */
var ablyChannel = ably.channels.get(channelName);
ablyChannel.subscribe(function(message) {
  log('Ably client received a message: ' + JSON.stringify(message.data));
});

/* PUBNUB CLIENT LIB */
/* Instance the Pubnub library */
var pubnub = Pubnub({
  publish_key        : API_KEY,
  subscribe_key      : API_KEY,
  origin             : 'pubnub.ably.io',
  ssl                : true,
  no_wait_for_pending: true
});

/* Subscribe to the 'some_channel' channel with the Pubnub client */
pubnub.subscribe({
  channel : channelName,
  message : function(message) {
    log('Pubnub client received a message: ' + JSON.stringify(message));
  }
});

function log(text) {
  var date = new Date();
  var logLine = date.getHours() + ':' + date.getMinutes() + ':' + date.getSeconds() + ':' + date.getMilliseconds() + ': ' + text;
  console.log(logLine);
}

console.log("Press p<enter> to publish a message with the Pubnub client library, or a<enter> to publish with the Ably client library. Press q<enter> to quit.");
process.stdin.resume();
process.stdin.on('data', function (chunk) {
  switch(chunk.toString()) {
    case "a\n":
      ablyChannel.publish(null, { 'Some': 'JSON data sent by the Ably client library' });
      break;
    case "p\n":
      pubnub.publish({
        channel : channelName,
        message : { 'Some': 'JSON data sent by the Pubnub client library' }
      });
      break;
    case "q\n":
      ably.close();
      process.exit();
  }
});
