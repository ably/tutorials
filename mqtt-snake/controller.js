const mqtt = require('mqtt');
const keypress = require('keypress');

keypress(process.stdin);
process.stdin.setRawMode(true);
process.stdin.on('keypress', function (ch, key) {
  if (key) {
    console.log('Key clicked: ' +  key.name);
    if (key.ctrl && (key.name == 'c')) {
      process.stdin.pause();
    }
  }
});

var options = { keepAlive: 15,
  username: 'FIRST_HALF_OF_API_KEY',
  password: 'SECOND_HALF_OF_API_KEY',
  port: 8883
};
var client = mqtt.connect('mqtts:mqtt.ably.io', options);
client.on('connect', function () {
  console.log('connected!');
});
client.on('error', function(err){
  console.log(err);
  client.end();
});