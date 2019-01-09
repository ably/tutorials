
var express = require('express');
var Ably = require("ably");
var cookieParser = require('cookie-parser')
var path = require('path');

var rest = new Ably.Rest({ key: 'FJWZrQ.swLeTg:_R4gkfPIxXcj3tRy' });

var realtime = new Ably.Realtime('FJWZrQ.swLeTg:_R4gkfPIxXcj3tRy');


//Configure isProduction variable
const isProduction = process.env.NODE_ENV === 'production';

//Initiate our app
const app    = express();
const router = express.Router();
app.use(cookieParser());

var recipient = {
  device_id: '01D0BY616FCSGB14N5ZPYG0ZVY'
};

var clientRecipient = {
  client_id: 'test'
};

var notification = {
  notification: {
    title: 'Hello from Ably!'
  }
};

var data = {
  data: {
     "foo": "bar",
     "baz": "qux"
  }
};

var clientID = '';

app.get('/', function(req, res) {
    res.sendFile(path.join(__dirname + '/push.html'));
});

app.get('/auth', function (req, res) {
  var username = req.query.username;
  
  var tokenParams = {}; /* Use token defaults for now */
  
  /* Check if the user wants to log in */
    if (username !== undefined) {
    /* Issue a token request with pub & sub permissions on all channels +
       configure the token with an identity */
	   console.log(req.cookies.username);
    tokenParams = {
      'capability': { '*': ['publish', 'subscribe', 'push-admin', 'push-subscribe'] },
      'clientId': username
    };
  } else {
    /* Issue a token with subscribe privileges restricted to one channel
       and configure the token without an identity (anonymous) */
    tokenParams = {
      'capability': { 'notifications': ['subscribe'] }
    };
  }
  
  rest.auth.createTokenRequest(tokenParams, function(err, tokenRequest) {
    if (err) {
      res.status(500).send('Error requesting token: ' + JSON.stringify(err));
    } else {
      clientID = username;
	  res.setHeader('Content-Type', 'application/json');
      res.send(JSON.stringify(tokenRequest));
    }
  });

  });

var data = {"name":"testMessageName", "data":"testMessageData"};

app.post('/push', function(req, res) {
realtime.push.admin.publish(recipient, data, function(err) {
  if (err) {
    console.log('Unable to publish push notification; err = ' + err.message);
    return;
  }
  console.log('Push notification published');
});
});


var clientRecipient = {
  client_id: 'test'
};

app.get('/pushbyclient', function(req, res) {
realtime.push.admin.publish(clientRecipient, data, function(err) {
  if (err) {
    console.log('Unable to publish push notification; err = ' + err.message);
    return;
  }
  console.log('Push notification published');
});
});

function authenticate(userName, password) {
  return userName === user && password === pwd;
}	

app.listen(3000, () => console.log('Server running on http://localhost:3000/'));
