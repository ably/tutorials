var Ably = require('ably')
//replace with actual API key or token
var client = Ably.Realtime('apikey')
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
        //var deviceId = get device id from the request payload
        var deviceId = '0001E4YMQD00GW0X476W5TVBFE';
        var device = {
            id: deviceId,
            formFactor: 'phone',
            platform: 'ios'
        }
        client.push.admin.deviceRegistrations.save(device, (err, device) => {
            if(err){
                console.log('Error: ' + err)
            } else{
                console.log('Device registered:' + device.id)
                subscribeDevice(device)
            }
                
        })
    }
})

function subscribeDevice (device){
    var channelSub = {
        channel: 'push',
        deviceId: device.id
    }
    client.push.admin.channelSubscriptions.save(channelSub, (err, channelSub) => {
        if(err){
            console.log('Error: ' + err)
        } else{
            console.log('Device subscribed to push channel with deviceId' + device.id)
        }
    })
}

app.get('/', (req, res) => {
    console.log('iOS Push Notifications tutorial with Ably')
})

app.listen(3000, () => {
    console.log('APP LISTENING ON PORT 3000')
}) 


/*Steps to run this server */
// 1. Download the ably-js 1.1 node library using `npm install ably@beta`
// 2. Replace the 'apiKey' string with an actual key
// 3. Run the server using `node main.js`