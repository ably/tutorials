$(function() {
  /* Set up realtime library and authenticate using token issued from server */
  var ably = new Ably.Realtime({ authUrl: '/auth' });
  var answersChannel = ably.channels.get('wolfram:answers');
  var questionsChannel = ably.channels.get('wolfram:questions');

  var $answers = $('#answers'),
      $status = $('#status'),
      $askButton = $('#ask-btn'),
      $question = $('#question');

  /* Subscribe to answers published on this channel */
  answersChannel.subscribe(function(message) {
    var $question = $('<div class="question">').text(message.data.question);
    var $answer = $('<div class="answer">').text(message.data.answer);
    var $stat = $('<div class="stat">').text("Wolfram took " + message.data.wolframTime + "ms");
    $answers.prepend($('<div>').append($stat).append($question).append($answer));
  });

  $askButton.on('click', function() {
    var question = $question.val();
    if (question.replace(' ') != '') {
      /* Publish question to the Ably channel so that the queue worker receives it via queues */
      questionsChannel.publish('question', question, function(err) {
        if (err) {
          showStatus('Failed to publish question!');
          $question.val(question);
          return;
        }
        clearStatus();
      });
      showStatus('Sending question...');
      $question.val('');
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
