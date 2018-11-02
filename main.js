var apiKey = '<YOUR-API-KEY>';
var ably = new Ably.Realtime({
    key: apiKey
});

var metaChannel = ably.channels.get("[meta]channel.lifecycle");
var resultArea = document.getElementById("result");
resultArea.scrollTop = resultArea.scrollHeight;

metaChannel.subscribe('channel.occupancy', (msg) => {
    var msgJSONobj = JSON.parse(JSON.stringify(msg.data));
    console.log('JSON DATA IS ' + JSON.stringify(msg.data))
    var occupancyMetrics = msgJSONobj.status.occupancy.metrics
    if (occupancyMetrics && !msgJSONobj.name.includes('[meta]')) {
        resultArea.value += ('\n\n[META DATA - ' + (new Date().toLocaleTimeString()) + ' ]: Occupancy on channel "' + msgJSONobj.name + '" has been updated. New data is as follows:\n')
        resultArea.value += ('Connections: ' + occupancyMetrics.connections + ' \n')
        resultArea.value += ('Publishers: ' + occupancyMetrics.publishers + ' \n')
        resultArea.value += ('Subscribers: ' + occupancyMetrics.subscribers + ' \n')
        resultArea.value += ('Presence Connections: ' + occupancyMetrics.presenceConnections + ' \n')
        resultArea.value += ('Presence Members: ' + occupancyMetrics.presenceMembers + ' \n')
        resultArea.value += ('Presence Subscribers: ' + occupancyMetrics.presenceSubscribers + ' \n')
        resultArea.scrollTop = resultArea.scrollHeight;
    }
})
