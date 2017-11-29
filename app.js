const ably = Ably.Realtime('YOUR_API_KEY_GOES_HERE');

const customerId = (function () {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  const randomChar = () => chars[Math.floor(Math.random() * chars.length)];
  const idLength = 16;
  const id = new Array(idLength);
  for (let i = 0; i < idLength; i++) {
    id[i] = randomChar();
  }
  return id.join('');
})();

const outboundChannel = ably.channels.get('pizza:customer:' + customerId);
const inboundChannel = ably.channels.get('pizza:bot:' + customerId);
inboundChannel.subscribe(receiveMessage);

function receiveMessage(message) {
  setWaiting(false); // The bot has replied, so remove the waiting message
  appendMessageElement('bot', message.data);
}

function postMessage(message) {
  appendMessageElement('user', inputField.value.trim());
  setWaiting(true); // Add a temporary waiting message
  outboundChannel.publish('user', { user: customerId, message });
}

const inputField = document.getElementById('input-field');
const chatLog = document.getElementById('chat-log');

function processInput(e) {
  if (e.which !== 13) { // Character code 13 is the ENTER key
    return;
  }

  const message = inputField.value.trim();
  if (message.length > 0) {
    postMessage(message);
  }

  inputField.value = '';
}

function appendMessageElement(type, message) {
  const div = document.createElement('div');
  div.classList.add(type, 'message');
  div.textContent = message;
  chatLog.appendChild(div);

  const el = document.scrollingElement;
  el.scrollTop = el.scrollHeight;

  return div;
}

let waitingElement; // persist a reference to the HTML element

function setWaiting(isWaiting) { // isWaiting should be true or false
  if (isWaiting) {
    // If the waiting element already exists, remove it and re-add it so that it
    // is always the last message in the chat log:
    if (waitingElement) {
      waitingElement.remove();
    }
    // Note the "waiting" class which, if you're using the CSS provided in the
    // repository for this tutorial, will style the message so that it pulses
    // to indicate that something is happening in the background:
    waitingElement = appendMessageElement('waiting', 'typing ...');
  }
  else {
    // We'll call setWaiting(false) when the bot's response message is received,
    // which will trigger the following code to remove the waiting element:
    if (waitingElement) {
      waitingElement.remove();
      waitingElement = null;
    }
  }
}

function focusInputField() {
  inputField.focus();
}

// Re-focus the input field when the window regains focus:
window.addEventListener('focus', focusInputField);

// ... and if the user clicks anywhere else on the page:
document.body.addEventListener('click', focusInputField);

inputField.addEventListener('keydown', processInput);

// When the page loads for the first time, focus the input field by default:
focusInputField();
