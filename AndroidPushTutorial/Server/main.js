var Ably = require('ably')
//replace with actual API key or token
var client = Ably.Realtime(API_KEY)
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

app.get('/register', (req, res) => {
    
        console.log('Registering device')
        var deviceId = req.query.deviceId;
        var registrationToken = req.query.registrationToken;
        var clientId = req.query.clientId;
        //var deviceId and deviceToken to be received in the request object
        var recipientDetails = {
            //It's "fcm" for Android.
            transportType: 'fcm',
            //replace with actual device token
            registrationToken:registrationToken
        }

        var myDevice = {
            id: deviceId,
            clientId:clientId,
            formFactor: 'phone',
            metadata: 'PST',
            platform: 'android',
            push: {
                recipient: recipientDetails
            } 
        }
        client.push.admin.deviceRegistrations.save(myDevice, (err, device) => {
            if(err){
                console.log(err);
            } else{
                console.log(device);
                subscribeDevice(device);
                res.setHeader('Content-Type', 'application/json');
                res.send(device);
            }
                
        })
    
})

app.get('/push/device', function (req, res) {
  var deviceId = req.query.deviceId;

  var recipient = {
    deviceId: deviceId

  };
  var notification = {
    notification: {
      title: 'Hello from Ably!'
    }

  };
  realtime.push.publish(recipient, notification, function(err) {
    if (err) {
        console.log('Unable to publish push notification; err = ' + err.message);
        return;
    }
    console.log('Push notification published');
    res.send("Push Sent");
  });
})

function subscribeDevice (device){
    var channelSub = {
        channel: 'test_push_channel',
        deviceId: device.id
    }
    client.push.admin.channelSubscriptions.save(channelSub, (err, channelSub) => {
        if(err){
            console.log(err);
        } else{
            console.log('Device subscribed to push channel with deviceId' + device.id)
        }
    })
}

app.get('/', (req, res) => {
    console.log('Push Notifications tutorial with Ably')
})

app.listen(3000, () => {
    console.log('APP LISTENING ON PORT 3000')
})


/*Steps to run this server */
// 1. Download the ably-js 1.1 node library using `npm install ably`
// 2. Replace the 'API_KEY' string with an actual key
// 3. Run the server using `node main.js`