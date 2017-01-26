$(function() {
  /* Set up realtime library and authenticate using token issued from server */
  var ably = new Ably.Realtime({ authUrl: '/auth' });
  var filteredChannel = ably.channels.get('neutrino:filtered');
  var publishChannel = ably.channels.get('neutrino:raw');

  var $output = $('#output'),
      $status = $('#status'),
      $actionButton = $('#action-btn'),
      $text = $('#text');

  /* Subscribe to filtered text published on this channel */
  filteredChannel.subscribe(function(message) {
    var $filtered = $('<p>').text(message.data);
    var $stat = $('<div class="stat">').text("Neutrino took " + message.data.neutrinoTime + "ms");
    $output.prepend($('<div>').append($stat).append($filtered));
  });

  $actionButton.on('click', function() {
    var text = $text.val();
    if (text.replace(' ') != '') {
      /* Publish text to the Ably channel so that the queue worker receives it via queues */
      publishChannel.publish('text', text, function(err) {
        if (err) {
          showStatus('Failed to publish text!');
          $text.val(text);
          return;
        }
        clearStatus();
      });
      showStatus('Sending unfiltered bad text...');
      $text.val('');
    }
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
