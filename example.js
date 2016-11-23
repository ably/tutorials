const Pubnub = require("pubnub");

const API_KEY = "INSERT-YOUR-API-KEY-HERE"; // Add your API key here
if (API_KEY.indexOf("INSERT") === 0) {
  throw("Cannot run without an API key. Add your key to example.js");

/* Instance the Pubnub library */
var pubnub = Pubnub({
  publish_key        : API_KEY,
  subscribe_key      : API_KEY,
  origin             : 'pubnub.ably.io',
  ssl                : true,
  no_wait_for_pending: true
});
