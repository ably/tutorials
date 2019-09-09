const API_KEY = 'INSERT-YOUR-API-KEY-HERE'; /* Add your API key here */
if (API_KEY.indexOf('INSERT') === 0) {
    throw('Cannot run without an API key. Add your key to this file.');
}

module.exports = {
    API_KEY: API_KEY
};