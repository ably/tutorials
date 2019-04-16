var channelName = 'demo-' + Math.floor(Math.random() * 1000),
    ablyRest = new Ably.Rest({ key: '<YOUR-API-KEY>' }),
    restChannel = ablyRest.channels.get(channelName),
    $receivedLog = $('#received');


$('input#send').on('click', function() {
  var message = { data: $('input#msg-data').val() };
  var messageId = $('input#msg-id').val();
  /* If a message ID is provided, use this to enable idempotent publishing */
  /* In all Ably client libraries >= v1.2, idempotency is enabled by default */
  if (messageId.length > 0) {
    message.id = messageId;
  }
  $receivedLog.prepend($('<li style="color: #999">').text("Publishing message: " + JSON.stringify(message)));
  /* Publish the message object */
  restChannel.publish([message]);
});

/* Subscribe to published messages on the channel */
var ablyRealtime = new Ably.Realtime({ key: '<YOUR-API-KEY>' }),
    realtimeChannel = ablyRealtime.channels.get(channelName);
console.log('here')
realtimeChannel.subscribe(function(message) {
  var received = new Date(message.timestamp),
      messageText = received.getHours() + ":" + received.getMinutes() + ":" + received.getSeconds();
  messageText += " id:" + message.id + ", data:" + message.data;
  $receivedLog.prepend($('<li>').text("Message received at " + messageText));
});


/* 
 * Code to update the curl command in the demo to reflect the changes in the ID and channel name.
 * This code is not relevant to the idempotent demo
 */
function configureCurlCommand() {
  console.log("configire");
  var $curl = $('#curl');
  var messageId = $('input#msg-id').val();
  if (messageId.length === 0) { messageId = '[unique-id]'; }
  var curlText = $curl.
    text().
    replace(/channels\/[\w\-]+\/messages/, 'channels/' + channelName + '/messages').
  replace(/"id": "[^\"]+"/, '"id": "' + messageId + '"');
          
  $curl.text(curlText);
}
configureCurlCommand();
$('input#msg-id').change(configureCurlCommand);

