// This Ably client library is available due to the script in the HTML header:
const ably = Ably.Realtime('YOUR_API_KEY_GOES_HERE');

// Remember when creating your API key that you specified that it would only
// work for channels starting with the string "pizza:". When testing the script,
// try changing the channel name to something else and see how Ably emits an
// error to your browser developer console, thus demonstrating the safety of
// having the API key in a client-side browser script.
const channel = ably.channels.get('pizza:messages');
channel.subscribe(receiveMessage);

// Define the listener function used above, and have it add the received message
// to the chat log in the user interface:
function receiveMessage(message) {
  // The appendMessageElement function is defined further below.
  appendMessageElement('bot', message.data);
}

// Retrieve references to the message input field and the chat log container:
const inputField = document.getElementById('input-field');
const chatLog = document.getElementById('chat-log');

// Define an event listener function to be triggered when a key is pressed:
function processInput(e) {
  if (e.which !== 13) return; // If it's not the ENTER key, don't do anything

  const message = inputField.value.trim(); // Grab the trimmed input message
  if (message.length > 0) { // Don't post blank messages

    // Asynchronously post the message to the Ably channel. The channel
    // subscription we created above will echo the message shortly:
    channel.publish('user', message);
  }

  // Clear the input field, ready for the next message, then re-focus the field
  // so we can keep typing uninterrupted:
  inputField.value = '';
}

// Attach the above listener function to the message input field:
inputField.addEventListener('keydown', processInput);

// And finally, this function will append messages to the chat log. The first
// argument indicates whether the message comes from the user or the bot:
function appendMessageElement(type, message) {
  const div = document.createElement('div');

  // Add two CSS classes, because later we'll want to be able to visually
  // differentiate user messages from bot messages:
  div.classList.add(type, 'message');
  div.textContent = message;
  chatLog.appendChild(div);

  // If the conversation goes on for a while, messages will fall off the bottom
  // of the page. Instead, let's scroll to the bottom of the page automatically:
  const el = document.scrollingElement;
  el.scrollTop = el.scrollHeight;
}
