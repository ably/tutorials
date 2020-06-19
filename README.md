# Peer to Peer Static Web App built with Vue.js

## Explanation:

[Ably Channels](https://www.ably.io/channels) are multicast (many publishers can publish to many subscribers) and we can use them to build peer-to-peer apps.

"Peer to peer" (p2p) is a term from distributed computing that describes any system where many participants, often referred to as "nodes", can participate in some form of collective communication. The idea of peer to peer was popularised in early filesharing networks, where users could connect to each other to exchange files, and search operated across all of the connected users, there is a long history of apps built using p2p. In this demo, we're going to build a simple app that will allow one of the peers to elect themselves the **"leader"**, and co-ordinate communication between each instance of our app.

## What's a leader?

Horizontally scaled systems, like P2P, often incorporate some form of "leader election" - where all of the nodes in the system attempt to become the "leader". This "leader" will co-ordinate the work distributed amongst the peers. For the sake of this demo, we will not implement leader election, instead, one of the users is going to click a button that makes them the leader. We'll refer to them as the `host` throughout this tutorial, although really they are just another peer.

If you want to learn more about robust leader election patterns, [Microsoft have an excellent writeup](https://docs.microsoft.com/en-us/azure/architecture/patterns/leader-election)

## What are we going to build?

To demonstrate these concepts, we're going to build a simple app that keeps track of users as they join an Ably channel.
The `channel name` will be up to the `host` to define - by typing it into the UI. There's nothing special about the `host`, they're just the first one to click the `host` button.

Once a `host` has joined the `channel`, their browser will be listening for messages from `clients` joining the same `channel`, and keeping track each time somebody joins.
They'll also keep all the `clients` in sync, by sending the complete list of `clients` on every connection.

By the end of this demo, everyone that joins the `channel`, should see the name of every other participant in the browser UI - powered by multicast messages.

## A brief introduction to Vue.js before we start

> Vue (pronounced /vjuː/, like view) is a progressive framework for building user interfaces. It is designed from the ground up to be incrementally adoptable, and can easily scale between a library and a framework depending on different use cases. It consists of an approachable core library that focuses on the view layer only, and an ecosystem of supporting libraries that helps you tackle complexity in large Single-Page Applications. 
> <cite>-- [vue.js Github repo](https://github.com/vuejs/vue)</cite>

[Vue.js](https://vuejs.org/) is a single page app framework, and we will use it to build the UI of our app. Our Vue code lives in [index.js](index.js) - and handles all of the user interactions. We're using Vue because it doesn't require a toolchain and it provides simple binding syntax for updating the UI when data changes.

Our Vue app looks a little like this abridged sample:

```js
var app = new Vue({
  el: '#app',
  data: {
    greeting: "hello world",
    displayGreeting: true,
  }
  methods: {
    doSomething: async function(evt) { ... }
  }
});
```

It finds an element with the id of `app` in our markup, and treats any elements within it as markup that can contain `Vue Directives` - extra attributes to bind data and manipulate our HTML based on the applications state.

Typically, the Vue app makes data available (such as `greeting` in the above code snippet), and when that data changes, it'll re-render the parts of the UI that are bound to it.
Vue.js exposes a `methods` property, which we use to implement things like click handlers and callbacks from our UI, like the `doSomething` function above.

This snippet of HTML should help illustrate how Vue if-statements and directives work

```html
<div id="app">
    <div v-if="displayGreeting" v-on:click="doSomething">
        {{ greeting }}
    </div>
</div>
```

Here you'll see Vue's `v-if` directive, which means that this `div` and its contents will only display if the `displayGreeting` `data` property is true.
You can also see Vue's binding syntax, where we use `{{ greeting }}` to bind data to the UI.

**Vue is simple to get started with, especially with a small app like this, with easy to understand data-binding syntax.
Vue works well for our example here, because it doesn't require much additional code.**

## Ably channels and API keys

In order to run this app, you will need an Ably API key. If you are not already signed up, you can [sign up now for a free Ably account](https://www.ably.io/signup). Once you have an Ably account:

* Log into your app dashboard
* Under **“Your apps”**, click on **“Manage app”** for any app you wish to use for this tutorial, or create a new one with the “Create New App” button
* Click on the **“API Keys”** tab
* Copy the secret **“API Key”** value from your Root key, we will use this later when we build our app.

This app is going to use [Ably Channels](https://www.ably.io/channels) and [Token Authentication](https://www.ably.io/documentation/rest/authentication/#token-authentication).

## Making sure we send consistent messages by wrapping our Ably client

Next we're going to make a class called `PubSubClient` which will do a few things for us:

1. Allow us to call connect twice to the same channel to make our calling code simpler
2. Adds metadata to messages sent outwards, so we don't have to remember to do it in our calling code.

```js
class PubSubClient {
  constructor(onMessageReceivedCallback) {  
    this.connected = false;
    this.onMessageReceivedCallback = onMessageReceivedCallback;
  }
```

We define a constructor for the class and set up some values. These values are a property called `connected`, set to false, and `onMessageReceivedCallback` - a function passed to the constructor that we will use later when Ably messages arrive.

We're then going to define a `connect` function

```js
  async connect(identity, uniqueId) {
    if(this.connected) return;

    this.metadata = { uniqueId: uniqueId, ...identity };

    const ably = new Ably.Realtime.Promise({ authUrl: '/api/createTokenRequest' });
    this.channel = await ably.channels.get(`p2p-sample-${uniqueId}`);

    this.channel.subscribe((message) => {
      this.onMessageReceivedCallback(message.data, this.metadata);
    });

    this.connected = true;
  }
```

While we're making a connection, we're subscribing to an Ably Channel and adding a callback function that passes on the `data` property from any received message to the function that we pass to the constructor. This data is the JSON that our peers sent, along with some identifying `metadata` (like the user's `friendlyName` in this example).

We're also going to define a `sendMessage` function, which adds some functionality on top of the default Ably `publish()`.

```javascript
  sendMessage(message, targetClientId) {
    if (!this.connected) {
      throw "Client is not connected";
    }

    message.metadata = this.metadata;
    message.forClientId = targetClientId ? targetClientId : null;
    this.channel.publish({ name: "myMessageName", data: message});
  }
}
```

Whenever `sendMessage` is called, we're including the data stored in `this.metadata` that was set during construction (our clients friendlyName). This ensures that whenever a message is sent **from** a peer, it's always going to include the name of the person that sent it.

We're also making sure that if the message is **for** a specific peer - set using `targetClientId` - then this property is added to the message before we publish it on the Ably Channel.

We will pass this wrapper to the instances of our `P2PClient` and `P2PServer` classes, to make sure they publish messages in a predictable way.

## Creating our Vue app

The application is going to be composed of a `Vue` UI, and two main classes, `P2PClient` and `P2PServer`.

The `peer` who elects themselves as host will be the only one to have an instance of `P2PServer` and all of their `peers` will be `P2PClients`.

When we define our Vue app, we're going to create two `null` properties inside of `Vue.data`:

```js
var app = new Vue({
  el: '#app',
  data: {
    p2pClient: null,
    p2pServer: null,
  ...
```

When a Vue instance is created, it adds all the properties found in its data object to Vue’s **reactivity system**. When the values of those properties change, the view will “react”, updating to match the new values.

By defining both our `p2pClient` and `p2pServer` properties inside of Vue's data object, we make them **reactive**, so any changes observed to the properties, will cause the UI to re-render.

Our Vue app only contains two functions, one to start `hosting` and the other to `join`. In reality, they're both doing the same thing (connecting to an Ably channel by name), but depending on which button is clicked in our UI, that `peer` will either behave as a host or a client.

```js
    host: async function(evt) {
      evt.preventDefault();

      const pubSubClient = new PubSubClient((message, metadata) => {
        handleMessagefromAbly(message, metadata, this.p2pClient, this.p2pServer);
      });

      const identity = new Identity(this.friendlyName);
      this.p2pServer = new P2PServer(identity, this.uniqueId, pubSubClient);
      this.p2pClient = new P2PClient(identity, this.uniqueId, pubSubClient);

      await this.p2pServer.connect();
      await this.p2pClient.connect();
    },
```

The `host` function, creates an instance of the `PubSubClient`, and provides it with a callback to `handleMessageFromAbly` then:

* Creates a new `Identity` instance, using the `friendlyName` bound to our UI
* Creates a new `P2PServer`
* Creates a new `P2PClient`
* Connects to each of them (which in turn, calls `connect` on our `PubSubClient` instance)

Joining is very similar

```js

    join: async function(evt) {
      evt.preventDefault();

      const pubSubClient = new PubSubClient((message, metadata) => {
        handleMessagefromAbly(message, metadata, this.p2pClient, this.p2pServer);
      });

      const identity = new Identity(this.friendlyName);
      this.p2pClient = new P2PClient(identity, this.uniqueId, pubSubClient);

      await this.p2pClient.connect();
    }
```

Here, we're doing *exactly the same* as the host, except we're only creating a `P2PClient`.

## HandleMessageFromAbly

`handleMessageFromAbly` is the callback function that the `PubSubClient` will trigger whenever a message appears on the `Ably Channel`.

```js
function shouldHandleMessage(message, metadata) {  
  return message.forClientId == null || !message.forClientId || (message.forClientId && message.forClientId === metadata.clientId); 
}

function handleMessagefromAbly(message, metadata, p2pClient, p2pServer) {
  if (shouldHandleMessage(message, metadata)) {
    p2pServer?.onReceiveMessage(message);  
    p2pClient?.onReceiveMessage(message);
  } 
}
```

It is responsible for calling any p2pServer `onReceiveMessage` if the client is a `host`, calling `onReceiveMessage` on our client. It also makes sure that if a message has been flagged as for a specific client, by including the property `forClientId`, that it doesn't get processed by other peers.

This is deliberately **not secure**. All the messages sent on our Ably channel are multicast, and received by all peers, so it should not be considered tamper proof - but it does prevent us having to filter inside the client and server instances.

## P2PClient

The `P2PClient` class does most of the work in the app.
It is responsible for sending a `connected` message over the `PubSubClient` when `connect` is called, and most importantly of keeping track of a copy of the `serverState` whenever a message is received.

```js
class P2PClient {
    constructor(identity, uniqueId, ably) {
      this.identity = identity;
      this.uniqueId = uniqueId;
      this.ably = ably;

      this.serverState = null;
      this.state = { status: "disconnected" };
    }
```

The constructor assigns parameters to instance variables, and initilises a `null` `this.serverState` property, along with its own client state in `this.state`.

We then go on to define the `connect` function

```js
    async connect() {
      await this.ably.connect(this.identity, this.uniqueId);

      this.ably.sendMessage({ kind: "connected" });
      this.state.status = "awaiting-acknowledgement";
    }
```

This uses the provided `PubSubClient` (here stored as the property `this.ably`) to send a `connected` message. The `PubSubClient` is doing the rest of the work - adding in the `identity` of the sender during the `sendMessage` call.

It also sets `this.state.status` to `awaiting-acknowledgement` - the default state for all of our client instances until the `P2PServer` has sent them a `connection-acknowledged` message.

`OnReceiveMessage` does a little more work:

```js  
    onReceiveMessage(message) {
      if (message.serverState) {
        this.serverState = message.serverState;
      }

      switch(message.kind) {
        case "connection-acknowledged":
          this.state.status = "acknowledged";
          break;
        default: () => { };
      }
    }
  }
```

There are two things to pay close attention to here - firstly that we update the property `this.serverState` whenever an incoming message has a property called `serverState` on it - our clients use this to keep a local copy of whatever the `host` says its state is, and we'll use this to bind to our UI later.

Then there's our switch on `message.kind` - the type of message we're receiving.

In this case, we only actually care about the `connection-acknowledged` message, updating the `this.state.status` property to `acknowledged` once we receive one.

## P2PServer

Our `P2PServer` class hardly differs from the client.

It contains a constructor that creates an empty `this.state` object

```js
class P2PServer {
    constructor(identity, uniqueId, ably) {
      this.identity = identity;
      this.uniqueId = uniqueId;
      this.ably = ably;

      this.state = { players: [] };
    }
```

A connect function that connects to Ably via the `PubSubClient`

```js
    async connect() {
      await this.ably.connect(this.identity, this.uniqueId);
    }
```

And an `onReceiveMessage` callback function that responds to the `connected` message.

```js
    onReceiveMessage(message) {
      switch(message.kind) {
        case "connected": this.onClientConnected(message); break;
        default: () => { };
      }
    }
```

All of the work is done in `onClientConnected`

```js
    onClientConnected(message) {
      this.state.players.push(message.metadata);
      this.ably.sendMessage({ kind: "connection-acknowledged", serverState: this.state }, message.metadata.clientId);
      this.ably.sendMessage({ kind: "peer-status", serverState: this.state });
    }  
  }
```

When a client connects, we keep track of their `metadata` (the `friendlyName`), and then send two messages.
The first, is a `connection-acknowledged` message, that is sent **specifically** to the `clientId` that just connected.

Then, it sends a `peer-status` message, with a copy of the latest `this.state` object, that will in turn trigger all the clients to update their internal state.

## Updating the UI when the internal state of the client updates

We have to write some markup allow the UI to update when the state changes.

We'll start off with a HTML document and some script tags

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>P2P Example</title>

    <script src="//cdn.ably.io/lib/ably-1.js" defer></script>
    <script src="//cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>

    <script src="/p2p.js" defer></script>
    <script src="/p2p.lib.server.js" defer></script>
    <script src="/p2p.lib.client.js" defer></script>
    <script src="/index.js" defer></script>

    <link rel="stylesheet" href="/style.css" />
  </head>
```

We're including:

* The latest `Ably JavaScript SDK`
* The `Vue` library from their CDN
* Our code, split across a few files for organisation.
* p2p.js - contains our `PubSubClient` and `Identity` classes
* p2p.lib.server.js - contains our `P2PServer` class
* p2p.lib.client.js - contains our `P2PClient` class
* index.js - contains our `Vue` app.

The files are split up with the expectation that the `P2PClient` and `P2PServer` code would likely grow over time, with additional messages being introduced and handled.

Now let's fill out the body:

```html
  <body>
    <div id="app">
      <h1>P2P Host / Client Example</h1>

      <div class="debug">
        Client State: {{ state?.status == undefined ? "Disconnected" : state?.status }}
      </div>
```

The `Vue` app is bound to the `div` with the id `app` - this means that all the markup inside that `div` is parsed for `Vue directives`.

Firstly, we're creating a form, to allow users to `host` or `join` a session.

```html
      <form class="form" v-if="!joinedOrHosting">
        <label for="session-name">Enter a name for your session</label>
        <input type="text" name="session-name" v-model="uniqueId">
        <label for="name-name">Enter your name</label>
        <input type="text" name="name" v-model="friendlyName">

        <button v-on:click="host" class="form-button form-button--host">Host a Session</button>
        <button v-on:click="join" class="form-button">Join a Session</button>
      </form>

```

Most of this is normal HTML, but there are a couple of small details worth paying attention to.
The `v-if` directive, on the first line can be read as "only display this element, if the following condition is met`.

`joinedOrHosting` is a property defined in our `Vue` app that looks like this

```js
  computed: {
    joinedOrHosting: function () { return this.p2pClient != null || this.p2pServer != null; },
  },
```

This `computed` property can be bound to, and is used to toggle the UI if our user hasn't `joined` or `hosted` yet - we've achieved this with a **null check** - because we know that our `this.p2pClient` and `this.p2pServer` instances are only created when our `host` or `join` functions are called.

Our buttons also have `v-on:click="host"` attributes in them - this is Vue's onclick handler binding syntax, which wires up our buttons to our Vue app functions. We only have two functions to call, so each of those `v-on:click` handlers only differ by the word `host` or `join`.

We then have some markup to render the `game-info`:

```html
      <section v-else class="game-info">
        <h2>UniqueId: {{ uniqueId }}</h2>
        <h3>Active players: {{ transmittedServerState?.players?.length }}</h3>
        <ul class="players">
          <li class="player" v-for="user in transmittedServerState?.players">
            <span>{{ user.friendlyName }}</span>
          </li>
        </ul>
      </section>
    </div>
  </body>
</html>
```

Here you'll notice Vue's `template syntax` - {{ some-property-name }} - by using this syntax, Vue will populate the markup with data sourced from it's data object. We're also using a `v-else` directive to toggle between the form and this information once a user clicks a button.

The `v-for` directive on the `li` element will loop for each element of the `players` collection, allowing us to output each `user.friendlyName` using just one line of markup.

This markup, binds to our final Vue app in [index.js](index.js):

```js
var app = new Vue({
  el: '#app',
  data: {
    p2pClient: null,
    p2pServer: null,

    friendlyName: "Player-" + crypto.getRandomValues(new Uint32Array(1))[0],
    uniqueId: "Session"
  },
  computed: {
    state: function() { return this.p2pClient?.state; },
    transmittedServerState: function() { return this.p2pClient?.serverState; },
    joinedOrHosting: function () { return this.p2pClient != null || this.p2pServer != null; },
  },
  methods: {
    host: async function(evt) { ... },
    join: async function(evt) { ... },
  }
});
```

Referencing both the `data` object properties, and our extra `computed` object properties.

## You now have a working peer to peer demo, but wait there's more!

This is a self contained demo of building peer to peer apps, hosting in browser tabs and using Ably Channels as the communication medium.

We'd love to see what exciting apps or games you could build on top of this sort of pattern - and to that end, we made one ourselves!

We made a distributed bingo game called `Ablingo` on top of this code sample - by adding additional messages, logic, and state to our server. You can read a detailed readme of how we extended this sample at the [repository here](https://github.com/thisisjofrank/Ablingo/blob/master/readme.md).

## Running the demo on your machine

While this whole application runs inside a browser, to host it anywhere people can use, we need a backend to keep our `Ably API key` safe. The running version of this app is hosted on [Azure Static Web Apps](https://azure.microsoft.com/en-gb/services/app-service/static/) and provides us a serverless function that we can use to implement [Ably Token Authentication](https://www.ably.io/documentation/realtime/authentication#token-authentication).

We need to keep the `Ably API key` on the server side, so people can't grab it and use up your personal quota. The client side SDK can request a temporary key from an API call, we just need somewhere to host it. In the `api` directory, there's code for an `Azure Functions` API that implements this `Token Authentication` behaviour.

Azure Static Web Apps automatically hosts this API for us. To have this same experience locally, we'll need to use the [Azure Functions Core Tools](https://docs.microsoft.com/en-us/learn/modules/develop-test-deploy-azure-functions-with-core-tools/).

### Local dev pre-requirements

We'll use [live-server](https://www.npmjs.com/package/live-server) to serve the static files and [Azure functions core tools](https://www.npmjs.com/package/azure-functions-core-tools) for interactivity. In your project folder run:

```bash
$ npm install -g live-server
$ npm install -g azure-functions-core-tools
```

Than set your API key for local dev:

```bash
$ cd api
$ func settings add ABLY_API_KEY Your-Ably-Api-Key
```

Running this command will encrypt your API key into the file `/api/local.settings.json`.
You don't need to check it in to source control, and even if you do, it won't be usable on another machine.

### How to run for local dev

To run the app:

```bash
$ npx live-server --proxy=/api:http://127.0.0.1:7071/api
```

And run the APIs

```bash
$ cd api
$ npm run start
```

## Hosting on Azure

We're hosting this as a Azure Static Web Apps - and the deployment information is in [hosting.md](https://github.com/thisisjofrank/Ablingo/blob/master/readme.md#hosting-on-azure).