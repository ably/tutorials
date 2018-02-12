const Ably = require('ably');
const processMessage = require('./pizza');

exports.invokePizzaAssistant = function (req, res) {
  console.log(req.body);
  if (req.body && req.body.customerId) {
    const message = req.body.message;
    const context = req.body.context;
    const customerId = req.body.customerId;
    const response = processMessage(req.body.message, context);

    // Note that we use uses Ably.Rest here, not Realtime, because we don't want
    // to start a websocket connection to Ably just to publish a single response;
    // doing so would be inefficient.
    const ably = new Ably.Rest('YOUR_API_KEY_GOES_HERE');

    // Get the pizza bot's response channel
    const channel = ably.channels.get('pizza:bot:' + customerId);

    // Publish the response, and handle any unexpected errors
    channel.publish('bot', response, err => {
      if (err) {
        console.log(err); // Use the Azure logging console to see this output
        res.status(500).send('Error publishing response back to Ably');
      }
      else {
        res.status(200).send('OK');
      }
    });
  }
  else {
    res.status(400).send('Invalid request format');
  }
};