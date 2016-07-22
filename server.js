const Ably = require("ably");

const ApiKey = "INSERT-YOUR-API-KEY-HERE"; /* Add your API key here */
if (ApiKey.indexOf("INSERT") === 0) { throw("Cannot run without an API key. Add your key to example.js"); }

/* Instance the Ably REST server library */
var rest = new Ably.Rest({ key: ApiKey });
