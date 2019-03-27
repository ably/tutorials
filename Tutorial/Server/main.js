var Ably = require('ably')
//replace with actual API key or token
var client = Ably.Realtime(YOUR_API_KEY)
var express = require('express')
var app = express()

app.get('/auth', (req, res) => {
    var tokenParams = {
        'clientId': req.query.clientId
      };
    console.log("Authenticating client:", JSON.stringify(tokenParams));
    client.auth.createTokenRequest(tokenParams, function(err, tokenRequest) {
      if (err) {
        res.status(500).send('Error requesting token: ' + JSON.stringify(err));
      } else {
        res.setHeader('Content-Type', 'application/json');
        res.send(JSON.stringify(tokenRequest));
      }
    });
})


app.get('/', (req, res) => {
    console.log('Push Notifications tutorial with Ably')
})

app.listen(3000, () => {
    console.log('APP LISTENING ON PORT 3000')
}) 


/*Steps to run this server */
// 1. Download the ably-js 1.1 node library using `npm install ably`
// 2. Replace the 'YOUR_API_KEY' string with an actual key
// 3. Run the server using `node main.js`