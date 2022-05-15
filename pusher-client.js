const Pusher = require('pusher-js');

const pusher = new Pusher('', {
    wsHost: 'realtime-pusher.ably.io',
    wsPort: 443,
    disableStats: false,
    encrypted: true,
});

pusher.connection.bind('connected', () => {
    console.log('connected');
});

pusher.connection.bind('disconnected', () => {
    console.log('disconnected');
});

pusher.connection.bind("error",  (error) => {
    console.error(error);
});

pusher.bind_global((eventName, data)=> {
    console.log("eventName-" + eventName + " data-" + JSON.stringify(data));
});

const channel = pusher.subscribe('some_channel');
channel.bind_global((eventName, data)=> {
    console.log("channel :: eventName-" + eventName + " data-" + JSON.stringify(data));
});

const channel1 = pusher.subscribe('private-channel');
channel1.bind_global((eventName, data)=> {
    console.log("channel :: eventName-" + eventName + " data-" + JSON.stringify(data));
});