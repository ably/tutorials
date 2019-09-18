const API_KEY = 'INSERT-YOUR-API-KEY-HERE'; /* Add your API key here */
if (API_KEY.indexOf('INSERT') === 0) {
    throw('Cannot run without an API key. Add your key to this file.');
}

/* Note: A sample cipher key is provided here for simplicity. Alternatively, one could use
the Ably.Realtime.Crypto.generateRandomKey() utility method to generate a valid key */
const SECRET = "AAECAwQFBgcICQoLDA0ODw==";

module.exports = {
    API_KEY: API_KEY,
    SECRET: SECRET
};
