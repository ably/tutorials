const express = require('express')
const Ably = require('Ably');
var realtime = new Ably.Realtime({key: "YOUR_API_KEY" });
const app = express()
const port = 3000
app.listen(port, () => console.log(`Example app listening on port ${port}!`))

app.get('/auth', function (req, res) {
  var tokenParams = {}; /* Use token defaults for now */
  realtime.auth.createTokenRequest(tokenParams, function(err, tokenRequest) {
    if (err) {
      res.status(500).send('Error requesting token: ' + JSON.stringify(err));
    } else {
      res.setHeader('Content-Type', 'application/json');
      res.send(JSON.stringify(tokenRequest));
    }
  });
});
