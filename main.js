let apiKey = 'YOUR_API_KEY';
let ably = new Ably.Realtime({
  key: apiKey,
});

let regularChannelName = "channel-" + Math.random().toString(36).substr(2, 16);
let channelOpts = { params: { occupancy: "metrics" } };
let channel = ably.channels.get(regularChannelName, channelOpts);
let resultArea = document.getElementById("result");
resultArea.scrollTop = resultArea.scrollHeight;

channel.subscribe("[meta]occupancy", (msg) => {
  let msgJSONobj = JSON.parse(JSON.stringify(msg));
  console.log("MSG: " + msg);
  //extract occupancy data from the message returned in the callback
  let occupancyMetrics = msgJSONobj.data.metrics;
  if (occupancyMetrics && msgJSONobj.name.includes("[meta]")) {
    resultArea.value +=
      "\n\n[METADATA - " +
      new Date().toLocaleTimeString() +
      ' ]: Occupancy on channel "' +
      regularChannelName +
      '" has been updated. New data is as follows:\n';
    resultArea.value += "Connections: " + occupancyMetrics.connections + " \n";
    resultArea.value += "Publishers: " + occupancyMetrics.publishers + " \n";
    resultArea.value += "Subscribers: " + occupancyMetrics.subscribers + " \n";
    resultArea.value +=
      "Presence Connections: " + occupancyMetrics.presenceConnections + " \n";
    resultArea.value +=
      "Presence Members: " + occupancyMetrics.presenceMembers + " \n";
    resultArea.value +=
      "Presence Subscribers: " + occupancyMetrics.presenceSubscribers + " \n";
    resultArea.scrollTop = resultArea.scrollHeight;
  }
});
