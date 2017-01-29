//= require jquery
//= require jquery_ujs
//= require_tree .

$(function() {
  /* Set up realtime library and authenticate using token issued from server */
  var ably = new Ably.Realtime({ authUrl: '/auth' });
  var publishChannel = ably.channels.get('chuck:ask');
  var jokeChannel = ably.channels.get('chuck:jokes');

  var $output = $('#output'),
      $status = $('#status'),
      $actionButton = $('#action-btn'),
      $text = $('#text');

  /* Subscribe to jokes published on this channel */
  jokeChannel.subscribe(function(message) {
    var $joke = $('<div class="joke">').text(message.data.joke);
    var $stat = $('<div class="stat">').text("Chuck's API took " + message.data.chuckTime + "ms");
    $output.prepend($('<div>').append($stat).append($joke));
  });

  $actionButton.on('click', function() {
    var text = $text.val();
    /* Publish text to the Ably channel so that the WebHook is triggered and delivered to the Rails app */
    publishChannel.publish('text', text, function(err) {
      if (err) {
        showStatus('Failed to publish request to Chuck!');
        $text.val(text);
        return;
      }
      clearStatus();
    });
    showStatus('Sending request to Chuck...');
    $text.val('');
  });

  ably.connection.on('connecting', function() { showStatus('Connecting to Ably...'); });
  ably.connection.on('connected', function() { clearStatus(); });
  ably.connection.on('disconnected', function() { showStatus('Disconnected from Ably...'); });
  ably.connection.on('suspended', function() { showStatus('Disconnected from Ably for a while...'); });

  function showStatus(text) {
    $status.text(text).show();
  }

  function clearStatus() {
    $status.fadeOut(750);
  }
});