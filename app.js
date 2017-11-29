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

function postMessage(message) {
  appendMessageElement('user', inputField.value.trim());
  outboundChannel.publish('user', { user: customerId, message });
}

function receiveMessage(message) {
  appendMessageElement('bot', message.data);
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

inputField.addEventListener('keydown', processInput);

function appendMessageElement(type, message) {
  const div = document.createElement('div');
  div.classList.add(type, 'message');
  div.textContent = message;
  chatLog.appendChild(div);

  const el = document.scrollingElement;
  el.scrollTop = el.scrollHeight;
}
