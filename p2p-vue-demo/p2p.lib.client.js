class P2PClient {
    constructor(identity, uniqueId, ably) {
      this.identity = identity;
      this.uniqueId = uniqueId;
      this.ably = ably;

      this.serverState = null;
      this.state = { status: "disconnected" };
    }

    async connect() {
      await this.ably.connect(this.identity, this.uniqueId);

      this.ably.sendMessage({ kind: "connected" });
      this.state.status = "awaiting-acknowledgement";
    }
  
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