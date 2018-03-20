const mqtt = require('mqtt');
const keypress = require('keypress');

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

keypress(process.stdin);

process.stdin.setRawMode(true);

process.stdin.on('keypress', function (ch, key) {
  if (key) {
    if (key.name == 'escape') {
      process.stdin.pause();
      client.end();
    } else if(key.name == 'left') {
      publishMessage('input', 'left');
    } else if(key.name == 'right') {
      publishMessage('input', 'right');
    } else if(key.name == 'up') {
      publishMessage('input', 'up');
    } else if(key.name == 'down') {
      publishMessage('input', 'down');
    } else if(key.name == 'space') {
      publishMessage('input', 'startstop');
    }
  }
});

function publishMessage(channel, message) {
  client.publish(channel, message, { qos: 0 }, function(err) {
    if(err) {
      console.log(err);
    }
  }); 
}