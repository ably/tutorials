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

  async sendWordsAcrossMultipleMessages() {
    const phrase = "Given the context of this talk, I think it’s quite easy to fall into the trap of thinking that visual design principles only apply to visual interfaces. If you ask a typical developer - the people we’re talking to - you could very quickly think that the visual aspects of what they think about are, you know, the marketing collateral, the website, potentially, even the documentation. And I think that’s partly true. I think, you know, what we’re actually dealing with as developers, right? And they spend most of their time, when they interact with us in our APIs, they’re spending most of their time in code, right? And those are the APIs that they expose to, and that’s the experience they have. So, you know, the same sort of design principles that we apply generally to visual design, you know, to things like documentation, which I’m sure we’ve all had experience sort of thinking about how we make that aesthetically better and how we lay their content out, I think you have to go through those same, the same ideas when you’re designing APIs. And this is what this talk is about. So I don’t think anyone’s going to disagree that, you know, design is important. But I wanted to kind of summarize why I think design matters. And, you know, I kind of distil this down into three things. And, you know, even as a developer, I mean, you know, I’m probably happier sitting writing code. Design is function But I sincerely appreciate the value of design, and the impact it has, and how it changes your perception of the thing that you’re interacting with. And so, you know, I think the first thing is really, when you think about design, design is function, right? Design is not just design in isolation. And Steve Jobs kind of coined this pretty well, which is, you know, “Design is not what it looks like and feels like, design is how it works.” And, you know, I think if you embody that sort of thinking that the two fit together, right, like, good design and bad function, or, you know, great function but terrible design, will still result in a pretty bad experience. So, you know, I think the important thing to remember is that those two things together is what delivers a good design experience. And the whole idea of the design process is about also reviewing the function.".split(" ");
    const sleep = (ms) => (new Promise(resolve => setTimeout(resolve, ms)));

    for (let word of phrase) {
      this.ably.sendMessage({ kind: "word", word: word, serverState: this.state });
      await sleep(500);
    }
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