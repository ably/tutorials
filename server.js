const express = require("express");
const cors = require("cors");
const Pusher = require("pusher");

const API_KEY = ''; // Replace this with your API key
if (API_KEY.indexOf("appid") === 0) {
    throw("Cannot run without an API key. Add your key to example.js");
}
const APP_ID = API_KEY.split('.')[0],
KEY_PARTS = API_KEY.split(':'),
KEY_NAME = KEY_PARTS[0],
KEY_SECRET = KEY_PARTS[1];

const pusher = new Pusher({
    appId     : APP_ID,
    key       : KEY_NAME,
    secret    : KEY_SECRET,
    host      : 'rest-pusher.ably.io',
    useTLS : true
});

const app = express();

app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cors());

// test ping-pong message
app.get("/ping", (_req, res) => {
  res.send("pong");
});

app.post("/ably/auth", (req, res) => {
  const socketId = req.body.socket_id;
  const channel = req.body.channel_name;
  if (channel.startsWith("private-")) {
     res.send(pusher.authenticate(socketId, channel)); //  returns signed token containing socketId and channelName using config. secret
  } else { 
    const presenceData = {
        user_id: "unique_user_id",
        user_info: { name: "Mr sac", twitter_id: "@pusher" },
    };
    res.send(pusher.authenticate(socketId, channel, presenceData)); // returns signed token containing socketId, channelName and userData using config. secret
  }
});

const port = process.env.PORT || 5000;
app.listen(port, (error) => {       // Listen
  if(!error)
      console.log(`Server is Successfully Running, and App is listening on port ${port}`);
  else
      console.log("Error occured, server can't start", error);
  }
);