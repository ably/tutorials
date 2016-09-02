const Ably = require("ably");

const ApiKey = "INSERT-YOUR-API-KEY-HERE"; /* Add your API key here */
if (ApiKey.indexOf("INSERT") === 0) { throw("Cannot run without an API key. Add your key to example.js"); }

console.log("Run this script in multiple consoles concurrently.");
console.log("Each script will simultaneously receive the published message as all clients are subscribed to the 'sport' channel.");

/* Instance the Ably library */
var realtime = new Ably.Realtime({ key: ApiKey });

/* Subscribe to messages on the sport channel */
var channel = realtime.channels.get("sport");
channel.subscribe(function(msg) {
  console.log("Received: " + JSON.stringify(msg.data));
});

console.log("Press <enter> to publish a message. Use <ctrl>-c to stop.");

/* Publish a message when enter is pressed */
process.stdin.resume();
process.stdin.on('data', function (chunk) {
  if (chunk.toString() === "\n") {
    channel.publish("update", { "team": "Man United" });
  }
});
