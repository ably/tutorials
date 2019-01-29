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

app.get('/subscribe', (req, res) => {
  console.log('Registering device')
  //will need to inspect the request to see if this works
  var deviceId = req.query.deviceId
  console.log('Device Id ' + deviceId)
  var deviceToken = req.query.deviceToken
  var recipientDetails = {
            transportType: 'apns',
            //replace with actual device token
            deviceToken: deviceToken
  }
  var device = {
    id: deviceId,
    formFactor: 'phone',
    metadata: 'PST',
          platform: 'ios',
          push: {
              recipient: recipientDetails
          }
  }
  realtime.push.admin.deviceRegistrations.save(device, (err, device) => {
      if(err){
          console.log('Error: ' + err)
          res.status(500).send('Error registering: ' + JSON.stringify(err));
      } else{
          console.log('Device registered:' + device.id)
          subscribeDevice(device)
      }
      res.send('Complete')
  })
})
function subscribeDevice (device){
  var channelSub = {
      channel: 'push',
      deviceId: device.id
  }
  realtime.push.admin.channelSubscriptions.save(channelSub, (err, channelSub) => {
      if(err){
          console.log('Error: ' + err)
      } else{
          console.log('Device subscribed to push channel with deviceId' + device.id)
      }
  })
}

app.get('/push/device', function (req, res) {
  var recipient = {
    deviceId: 'YOUR_DEVICE_ID'
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

app.get('/push/client', function (req, res) {
  var recipient = {
    clientId: 'ios:push'
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

app.get('/push/channel', function (req, res) {
  var extras = {
    push: {
      notification: {
        title: 'Hello from Ably!',
        body: 'Example push notification from Ably.'
      },
      data: {
        foo: 'bar',
        baz: 'qux'
      }
    }
  };
  var channel = realtime.channels.get('push');
  channel.publish({ name: 'example', data: 'data', extras: extras }, function(err) {
    if (err) {
      console.log('Unable to publish message with push notification; err = ' + err.message);
      return;
    }
    console.log('Message with push notification published');
    res.send("Push Sent");
  });
})
