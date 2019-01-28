var Ably = require('ably')
var client = Ably.Realtime('apiKey')
var express = require('express')
var app = express()

app.get('/auth', (req, res) => {
    var tokenParams = {
        'clientId': uniqueId()
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

app.get('/register', (req, res) => {
    if (err){
        res.status(500).send('Error: ' + JSON.stringify(err))
    } else {
        console.log('Registering device')
        //will need to inspect the request to see if this works
        var deviceId = req.deviceId 
        //save(DeviceDetails device, callback(ErrorInfo err, DeviceDetails device))
        var device = new DeviceDetails({
            id: deviceId,
            formFactor: 'phone',
            platform: 'ios'
        })
        client.push.admin.deviceRegistrations.save(device, (err, device) => {
            if(err)
                console.log('Error: ' + err)
        })
    }
})

app.get('/', (req, res) => {
    console.log('iOS Push Notifications tutorial with Ably')
})

app.listen(3000, () => {
    console.log('APP LISTENING ON PORT 3000')
})