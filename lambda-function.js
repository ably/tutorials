const https = require("https")
const AWS = require('aws-sdk');

// -----------------------------------------
const ablyApiKey = 'YOUR_API_KEY_GOES_HERE';
// -----------------------------------------

exports.handler = (event, context, callback) => {
  const lex = new AWS.LexRuntime();
  const data = JSON.parse(event.messages[0].data);
  const channel = 'pizza:bot:' + data.user;
  const onResponse = (err, result) => err
    ? callback(err)
    : postMessage(ablyApiKey, channel, result.message, callback);

  lex.postText({
    botName: 'PizzaAssistant',
    botAlias: 'PizzaAssistant',
    userId: data.user,
    inputText: data.message
  }, onResponse);
};

function postMessage(apiKey, channel, message, callback) {
  const data = JSON.stringify({
    name: 'bot',
    data: message
  });

  const options = {
    host: 'rest.ably.io',
    port: 443,
    path: `/channels/${channel}/messages`,
    method: 'POST',
    headers: {
      'Authorization': `Basic ${new Buffer(apiKey).toString('base64')}`,
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(data)
    }
  };

  const req = https.request(options, (res) => {
    let output = '';
    res.setEncoding('utf8');
    res.on('data', (chunk) => output += chunk);
    res.on('end', () => (statusCode, result) => {
      callback(null, { statusCode, result });
    });
  });

  req.on('error', (err) => {
    callback(err);
  });

  req.write(data);
  req.end();
}
