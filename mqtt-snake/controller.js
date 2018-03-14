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
