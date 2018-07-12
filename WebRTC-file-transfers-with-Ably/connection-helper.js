class Connection {
    constructor(remoteClient, AblyRealtime, initiator) {
        console.log(`Opening connection to ${remoteClient}`);
        this._remoteClient = remoteClient;
        this.isConnected = false;
        this._p2pConnection = new SimplePeer({
            initiator: initiator,
            trickle: false,
        });
        this._p2pConnection.on('signal', this._onSignal.bind(this));
        this._p2pConnection.on('error', this._onError.bind(this));
        this._p2pConnection.on('connect', this._onConnect.bind(this));
        this._p2pConnection.on('close', this._onClose.bind(this));
        this._p2pConnection.on('data', this._onData.bind(this));
    }
    handleSignal(signal) {
        this._p2pConnection.signal(signal);
    }
    send(msg) {
        this._p2pConnection.send(msg);
    }
    _onSignal(signal) {
        AblyRealtime.publish(`ablywebrtc-signal/${this._remoteClient}`, {
            user: clientId,
            signal: signal,
        });
    }
    _onConnect() {
        this.isConnected = true;
        console.log('connected to ' + this._remoteClient);
    }
    _onClose() {
        console.log(`connection to ${this._remoteClient} closed`);
        delete connections[this._remoteClient];
    }
    _onData(data) {
        recieveMessage(this._remoteClient, data)
    }
    _onError(error) {
        console.log(`an error occured ${error.toString()}`);
    }
}