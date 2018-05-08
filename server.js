var jwt = require("jsonwebtoken")
//You must use your own API key
//For a dummy API key I2E_JQ.79AfrA:sw2y9zarxwl0Lw5a
var appId = 'I2E_JQ'
var keyId = '79AfrA'
var keySecret = 'sw2y9zarxwl0Lw5a'
var ttlSeconds = 60

var jwtPayload =
    {
        'x-ably-capability': JSON.stringify({ '*': ['publish', 'subscribe'] })
    }
var jwtOptions =
    {
        expiresIn: ttlSeconds,
        keyid: `${appId}.${keyId}`
    }

var express = require('express'),
    app = express();
app.use('/', express.static(__dirname))
app.get('/auth', function (req, res) {
    console.log('Sucessfully connected to the server auth endpoint')
    jwt.sign(jwtPayload, keySecret, jwtOptions, function (err, tokenId) {
        console.log('JSON Web Token signed by auth server')
        if (err) {
            console.trace()
            return
        }
        res.setHeader('Content-Type', 'application/json');
        console.log('Sending signed JWT token back to client')
        res.send(JSON.stringify(tokenId));
    })
});
app.listen(3000, function () {
    console.log('Web server listening on port 3000');
});