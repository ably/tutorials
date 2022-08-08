const Ably = require("ably");

const apiKey = "YOUR_ABLY_API_KEY"; // Replace with your API key
const randomId =
  Math.random().toString(36).substring(2, 10) +
  Math.random().toString(36).substring(2, 10);
const realtime = new Ably.Realtime.Promise({
  key: apiKey,
  clientId: randomId, // Your ID in the presence set
});

async function doPresence() {
  // Connect to Ably
  await realtime.connection.once("connected");
  console.log("Connected to Ably!");

  // Attach to the "chatroom" channel
  const channel = realtime.channels.get("chatroom");
  await channel.attach((err) => {
    if (err) {
      return console.error("Error attaching to the channel.");
    }
  });

  // Enter the presence set of the "chatroom" channel
  await channel.presence.enter("hello", (err) => {
    if (err) {
      return console.error("Error entering presence set.");
    }
    console.log("This client has entered the presence set.");
  });

  // Subscribe to the presence set to receive updates
  await channel.presence.subscribe((presenceMessage) => {
    console.log(
      "Presence update: " +
        presenceMessage.action +
        " from " +
        presenceMessage.clientId
    );
    // Update the list of channel members when the presence set changes
    channel.presence.get((err, members) => {
      if (err) {
        return console.error(`Error retrieving presence data: ${err}`);
      }
      console.log(
        "The presence set now consists of: " +
          members
            .map((member) => {
              return member.clientId;
            })
            .join(", ")
      );
    });
  });
}

doPresence();
