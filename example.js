const Ably = require("ably");

const ApiKey = "INSERT-YOUR-API-KEY-HERE"; /* Add your API key here */
if (ApiKey.indexOf("INSERT") === 0) { throw("Cannot run without an API key. Add your key to example.js"); }

/* Instance the Ably library */
var realtime = new Ably.Realtime({ key: ApiKey });
