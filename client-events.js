console.warn("\n1. Make sure server is running i.e. `npm run server`"+
"\n2.Run two or more instances of client-events, one for sending and others for receiving client events")
console.warn("\nOnly compatible with unix/bash shell, git bash can be used in windows")

const Pusher = require('pusher-js');

const pusherRealtime = new Pusher('appid.keyid', {  // replace with first part of API key before :
    wsHost: 'realtime-pusher.ably.io',
    wsPort: 443,
    disableStats: false,
    useTLS: true,
    authEndpoint: 'http://localhost:5000/ably/auth', // deprecated
});

pusherRealtime.connection.bind('connected', () => {
    console.log('connected');
});

pusherRealtime.connection.bind('disconnected', () => {
    console.log('disconnected');
});

pusherRealtime.connection.bind("error",  (error) => {
    console.error(error);
});

pusherRealtime.bind_global((eventName, data)=> {
    console.log("Global eventName-" + eventName + " data-" + JSON.stringify(data));
});

const alpha = pusherRealtime.subscribe('private-alpha');
alpha.bind("pusher:subscription_succeeded", () => {
    console.log('subscribed to alpha')
});
alpha.bind("pusher:subscription_error", (err) => {
    console.error('alpha subscription error', err)
});
alpha.bind_global((eventName, data)=> {
    console.log("alpha :: eventName-" + eventName + " data-" + JSON.stringify(data));
});

const beta = pusherRealtime.subscribe('private-beta');
beta.bind("pusher:subscription_succeeded", () => {
    console.log('subscribed to beta')
});
beta.bind("pusher:subscription_error", (err) => {
    console.error('beta subscription error', err)
});
beta.bind_global((eventName, data)=> {
    console.log("beta :: eventName-" + eventName + " data-" + JSON.stringify(data));
});


console.log("\n1.Press A<enter> to send message via alpha\n2.Press B<enter> to send message to beta\nPress Q to quit");
process.stdin.resume();
process.stdin.on('data', function (chunk) {
  switch(chunk.toString()) {
    case "a\n":
    case "A\n":
      alpha.trigger('client-event', { 'msg': 'Hi from alpha' }); // https://pusher.com/docs/channels/using_channels/events/#eventname-1035650223
      break;
    case "b\n":
    case "B\n":
      beta.trigger('client-event', { 'msg': 'Hi from beta' });
      break;      
    case "q\n":
    case "Q\n":
      pusherRealtime.disconnect();
      process.exit();
  }
});
