class P2PServer {
    constructor(identity, uniqueId, ably) {
      this.identity = identity;
      this.uniqueId = uniqueId;
      this.ably = ably;

      this.state = { players: [] };
    }
     
    async connect() {
      await this.ably.connect(this.identity, this.uniqueId);
    }

    onReceiveMessage(message) {
      switch(message.kind) {
        case "connected": this.onClientConnected(message); break;
        default: () => { };
      }
    }

    onClientConnected(message) {
      this.state.players.push(message.metadata);
      this.ably.sendMessage({ kind: "connection-acknowledged", serverState: this.state }, message.metadata.clientId);
      this.ably.sendMessage({ kind: "peer-status", serverState: this.state });
    }  
  }