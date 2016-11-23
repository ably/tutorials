const Pusher = require("pusher");

const API_KEY = 'appid.keyid:keysecret'; // Replace this with your API key
if (API_KEY.indexOf("appid") === 0) {
  throw("Cannot run without an API key. Add your key to example.js");
}

const APP_ID = API_KEY.split('.')[0],
  KEY_PARTS = API_KEY.split(':'),
  KEY_NAME = KEY_PARTS[0],
  KEY_SECRET = KEY_PARTS[1];


/* Instance the Pusher library */
const pusher = new Pusher({
  appId     : APP_ID,
  key       : KEY_NAME,
  secret    : KEY_SECRET,
  host      : 'rest-pusher.ably.io',
  encrypted : true
});
