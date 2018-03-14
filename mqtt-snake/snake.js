var ably = new Ably.Realtime('REPLACE_WITH_YOUR_API_KEY');
var enc = new TextDecoder();
var channel = ably.channels.get('input');
channel.subscribe(function(message) {
  var command = enc.decode(message.data);
  console.log(command);
});
