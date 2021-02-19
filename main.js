function addPublisherInstance() {
    const str = 'Adding new publisher instance'
    localLog(str)
    const ably = new Ably.Realtime({
        key: apiKey,
    })
    const regularChannel = ably.channels.get(regularChannelName)
    regularChannel.publish('test-data', {
        data: 'Dummy Data',
        time: Date.now(),
    })
}

function addSubscriberInstance() {
    const str = 'Adding new subscriber instance'
    localLog(str)
    const ably = new Ably.Realtime({
        key: apiKey,
    })
    const regularChannel = ably.channels.get(regularChannelName)
    regularChannel.subscribe('test-data', (data) => {
        console.log('Subscription working')
    })
}

function addPublisherInstanceWithPresence() {
    const str = 'Adding new publisher instance with presence'
    localLog(str)
    const myId = 'clientId-' + Math.random().toString(36).substr(2, 16)
    const ably = new Ably.Realtime({
        key: apiKey,
        clientId: myId,
    })
    const regularChannel = ably.channels.get(regularChannelName)
    regularChannel.publish('test-data', {
        data: 'Dummy Data',
        time: Date.now(),
    })
    regularChannel.presence.enter()
}

function addSubscriberInstanceWithPresence() {
    const str = 'Adding new subscriber instance with presence'
    localLog(str)
    const myId = 'clientId-' + Math.random().toString(36).substr(2, 16)
    const ably = new Ably.Realtime({
        key: apiKey,
        clientId: myId,
    })
    const regularChannel = ably.channels.get(regularChannelName)
    regularChannel.subscribe('test-data', (data) => {
        console.log('Subscription working')
    })
    regularChannel.presence.enter()
}
