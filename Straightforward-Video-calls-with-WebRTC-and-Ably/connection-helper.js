class Connection {
    constructor(remoteClient, AblyRealtime, initiator, stream) {
        console.log(`Opening connection to ${remoteClient}`)
        this._remoteClient = remoteClient
        this.isConnected = false
        this._p2pConnection = new SimplePeer({
            initiator: initiator,
            stream: stream
        })
        this._p2pConnection.on('signal', this._onSignal.bind(this))
        this._p2pConnection.on('error', this._onError.bind(this))
        this._p2pConnection.on('connect', this._onConnect.bind(this))
        this._p2pConnection.on('close', this._onClose.bind(this))
        this._p2pConnection.on('stream', this._onStream.bind(this))
    }
    handleSignal(signal) {
        this._p2pConnection.signal(signal)
    }
    send(msg) {
        this._p2pConnection.send(msg)
    }
    destroy() {
        this._p2pConnection.destroy()
    }
    _onSignal(signal) {
        AblyRealtime.publish(`rtc-signal/${this._remoteClient}`, {
            user: clientId,
            signal: signal
        })
    }
    _onConnect() {
        this.isConnected = true
        console.log('connected to ' + this._remoteClient)
    }
    _onClose() {
        console.log(`connection to ${this._remoteClient} closed`)
        handleEndCall(this._remoteClient)
    }
    _onStream(data) {
        receiveStream(this._remoteClient, data)
    }
    _onError(error) {
        console.log(`an error occured ${error.toString()}`)
    }
}