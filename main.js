function addPublisherInstance() {
  console.log("API KEY: " + apiKey);
  resultArea.value +=
    "\n[LOCAL LOG - " +
    new Date().toLocaleTimeString() +
    " ]: Adding new publisher instance\n";
  let ably = new Ably.Realtime({
    key: apiKey,
  });
  let regularChannel = ably.channels.get(regularChannelName);
  console.log("adding publisher instance");
  regularChannel.publish("test-data", {
    data: "Dummy Data",
    time: Date.now(),
  });
}

function addSubscriberInstance() {
  resultArea.value +=
    "\n[LOCAL LOG - " +
    new Date().toLocaleTimeString() +
    " ]: Adding new subscriber instance\n";
  let ably = new Ably.Realtime({
    key: apiKey,
  });
  let regularChannel = ably.channels.get(regularChannelName);
  console.log("adding subscriber instance");
  regularChannel.subscribe("test-data", (data) => {
    //do whatever
    console.log("Subscription working");
  });
}

function addPublisherInstanceWithPresence() {
  resultArea.value +=
    "\n[LOCAL LOG - " +
    new Date().toLocaleTimeString() +
    " ]: Adding new publisher instance\n";
  let myId = "clientId-" + Math.random().toString(36).substr(2, 16);
  let ably = new Ably.Realtime({
    key: apiKey,
    clientId: myId,
  });
  let regularChannel = ably.channels.get(regularChannelName);
  console.log("adding publisher instance");
  regularChannel.publish("test-data", {
    data: "Dummy Data",
    time: Date.now(),
  });
  regularChannel.presence.enter();
}

function addSubscriberInstanceWithPresence() {
  resultArea.value +=
    "\n[LOCAL LOG - " +
    new Date().toLocaleTimeString() +
    " ]: Adding new subscriber instance\n";
  let myId = "clientId-" + Math.random().toString(36).substr(2, 16);
  let ably = new Ably.Realtime({
    key: apiKey,
    clientId: myId,
  });
  let regularChannel = ably.channels.get(regularChannelName);
  console.log("adding subscriber instance");
  regularChannel.subscribe("test-data", (data) => {
    //do whatever
    console.log("Subscription working");
  });
  regularChannel.presence.enter();
}
