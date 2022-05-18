const Pusher = require('pusher-js');

const pusher = new Pusher('', {
    wsHost: 'realtime-pusher.ably.io',
    wsPort: 443,
    disableStats: false,
    useTLS: true,
    authEndpoint: 'http://localhost:5000/ably/auth', // deprecated
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

const public_channel = pusher.subscribe('public-channel');
public_channel.bind("pusher:subscription_succeeded", () => {
    console.log('subscribed to public-channel')
});
public_channel.bind("pusher:subscription_error", (err) => {
    console.error('public channel subscription error', err)
});
public_channel.bind_global((eventName, data)=> {
    console.log("private channel :: eventName-" + eventName + " data-" + JSON.stringify(data));
});


const private_channel = pusher.subscribe('private-channel');
private_channel.bind("pusher:subscription_succeeded", () => {
    console.log('subscribed to private-channel')
});
private_channel.bind("pusher:subscription_error", (err) => {
    console.error('private channel subscription error', err)
});
private_channel.bind_global((eventName, data)=> {
    console.log("private channel :: eventName-" + eventName + " data-" + JSON.stringify(data));
});

// const presence_channel = pusher.subscribe('presence-channel');
// presence_channel.bind("pusher:subscription_succeeded", () => {
//     console.log('subscribed to presence-channel')
// });
// presence_channel.bind("pusher:subscription_error", (err) => {
//     console.error('presence channel subscription error', err)
// });
// presence_channel.bind_global((eventName, data)=> {
//     console.log("private channel :: eventName-" + eventName + " data-" + JSON.stringify(data));
// });