const Ably = require("ably");

const ApiKey = "INSERT-YOUR-API-KEY-HERE", /* Add your API key here */
  clientId = "my-client-id"; /* This is who you will appear as in the presence set */
if (ApiKey.indexOf("INSERT") === 0) { throw("Cannot run without an API key. Add your key to example.js"); }

/* Instance the Ably library */
var realtime = new Ably.Realtime({ key: ApiKey, clientId: clientId });

/* Enter the presence set of the 'chatroom' channel */
var channel = realtime.channels.get('chatroom');
channel.attach(function(err) {
  if(err) { return console.log("Error attaching to the channel"); }
  console.log('We are now attached to the channel');
  channel.presence.enter('hello', function(err) {
    if(err) { return console.error("Error entering presence"); }
    console.log('We are now successfully present');
  });
});
