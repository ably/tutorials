console.warn("Only compatible with unix/bash shell, git bash can be used in windows")
const Ably = require("ably");
const Pusher = require("pusher");

const API_KEY = 'appid.keyid:keysecret'; // Replace this with your API key
if (API_KEY.indexOf("appid") === 0) {
  throw("Cannot run without an API key. Add your key to example.js");
}

const APP_ID = API_KEY.split('.')[0],
  KEY_PARTS = API_KEY.split(':'),
  KEY_NAME = KEY_PARTS[0],
  KEY_SECRET = KEY_PARTS[1];

const pusherChannelName = 'some_channel';
const ablyChannelName = 'public:' + pusherChannelName;

/* ABLY CLIENT LIB */
/* Instance the Ably library */
const ably = new Ably.Realtime(API_KEY);

/* Subscribe to the 'some_channel' channel with the Ably client */
const ablyChannel = ably.channels.get(ablyChannelName);
ablyChannel.subscribe(function(message) {
  console.log('Ably client received a message: ' + message.name + ', data: ' + JSON.stringify(message.data));
});

/* PUSHER SERVER LIB */
/* Initiate the Pusher node library */
const pusherRest = new Pusher({
  appId     : APP_ID,
  key       : KEY_NAME,
  secret    : KEY_SECRET,
  host      : 'rest-pusher.ably.io',
  encrypted : true
});


console.log("Press p<enter> to publish a message with the Pusher nodejs library, and see it be received by the Ably client library. Press q<enter> to quit.");
process.stdin.resume();
process.stdin.on('data', function (chunk) {
  switch(chunk.toString()) {
    case "p\n":
    case "P\n":
      pusherRest.trigger(pusherChannelName, 'eventName', { 'Some': 'JSON data' });
      break;
    case "q\n":
    case "Q\n":
      ably.close();
      process.exit();
  }
});
