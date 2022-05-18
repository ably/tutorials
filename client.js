const Pusher = require('pusher-js');

const pusher = new Pusher('', {  // replace with first part of API key before :
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
    console.log("Global eventName-" + eventName + " data-" + JSON.stringify(data));
});

// Public channel -> Doesn't make any explicit request for authorization
const public_channel = pusher.subscribe('public-channel');
public_channel.bind("pusher:subscription_succeeded", () => {
    console.log('subscribed to public-channel')
});
public_channel.bind("pusher:subscription_error", (err) => {
    console.error('public channel subscription error', err)
});
public_channel.bind_global((eventName, data)=> {
    console.log("public channel :: eventName-" + eventName + " data-" + JSON.stringify(data));
});

// Private channel -> requests { 'auth' : 'token'} from /ably/auth
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

// Presence channel -> requests { 'auth' : 'token', 'channelData' : {'userId': '', userInfo: ''}} from /ably/auth
const presence_channel = pusher.subscribe('presence-channel');
presence_channel.bind("pusher:subscription_succeeded", (members) => {
    console.log('\n###subscribed to presence-channel###')
    console.log(`members count :: ${members.count}`)
    members.each((member) => {
        console.log(member.id, member.info)
    });
    console.log('#########\n')
});
presence_channel.bind("pusher:member_added", (member) => {
    console.log('\nmember added', member);
    console.log('updated members', presence_channel.members.count)
});
presence_channel.bind("pusher:member_removed", (member) => {
    console.log('\nmember removed', member)
    console.log('updated members', presence_channel.members.count)
});
presence_channel.bind("pusher:subscription_error", (err) => {
    console.error('presence channel subscription error', err)
});
presence_channel.bind_global((eventName, data)=> {
    console.log("presence channel :: eventName-" + eventName + " data-" + JSON.stringify(data));
});