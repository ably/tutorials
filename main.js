const apiKey = '<YOUR_ABLY_KEY>'
const ably = new Ably.Realtime({
    key: apiKey,
})

const regularChannelName = 'channel-' + Math.random().toString(36).substr(2, 16)
const channelOpts = { params: { occupancy: 'metrics' } }
const channel = ably.channels.get(regularChannelName, channelOpts)
const resultArea = document.getElementById('result')
resultArea.scrollTop = resultArea.scrollHeight

function localLog(msg) {
    const logDate = new Date().toLocaleTimeString()
    const template = `\n\n[LOCAL LOG - ${logDate}] - ${msg}\n`
    resultArea.value += template
    console.log(msg)
}

function logData(channelName, metrics) {
    const logDate = new Date().toLocaleTimeString()
    const prompt = `\n\n[METADATA - ${logDate}] - Occupancy on channel ${channelName} has been updated: \n`
    const template = `Connections: ${metrics.connections}
Publishers: ${metrics.publishers}
Subscribers: ${metrics.subscribers}
Presence Connections: ${metrics.presenceConnections}
Presence Members: ${metrics.presenceMembers}
Presence Subscribers: ${metrics.presenceSubscribers}`

    return prompt + template
}

channel.subscribe('[meta]occupancy', (msg) => {
    const occupancyMetrics = msg.data.metrics
    if (occupancyMetrics && msg.name.includes('[meta]')) {
        resultArea.value += logData(regularChannelName, occupancyMetrics)
        resultArea.scrollTop = resultArea.scrollHeight
    }
})
