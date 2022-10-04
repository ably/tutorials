const Ably = require("ably");

const apiKey = "YOUR_ABLY_API_KEY"; /* Add your API key here */
if (apiKey.indexOf("INSERT") === 0) {
  throw "Cannot run without an API key. Add your key to server.js";
}

/* Instantiate the Ably REST server library SDK */
const rest = new Ably.Rest({ key: apiKey });

/* Start the Express.js web server */
const express = require("express"),
  app = express(),
  cookieParser = require("cookie-parser");

app.use(cookieParser());

// Serve static content from the root path
app.use("/", express.static(__dirname));

// Issue token requests to clients sending a request to the /auth endpoint
app.get("/auth", (req, res) => {
  let tokenParams;
  // Check if the user is logged in
  if (req.cookies.username) {
    /* Issue a token with pub & sub privileges for all channels and
      configure the token with an client ID */
    tokenParams = {
      capability: { "*": ["publish", "subscribe"] },
      clientId: req.cookies.username,
    };
  } else {
    /* Issue a token request with sub privileges restricted to one channel
       and configure the token without a client ID (anonymous) */
    tokenParams = {
      capability: { notifications: ["subscribe"] },
    };
  }

  console.log("Sending signed token request:", JSON.stringify(tokenParams));

  rest.auth.createTokenRequest(tokenParams, (err, tokenRequest) => {
    if (err) {
      res.status(500).send(`Error requesting token: ${JSON.stringify(err)}`);
    } else {
      res.setHeader("Content-Type", "application/json");
      res.send(JSON.stringify(tokenRequest));
    }
  });
});

// Set a cookie when the user logs in
app.get("/login", (req, res) => {
  /* Login the user without credentials.
     This is an over-simplified authentication system
     to keep this tutorial simple */
  if (req.query["username"]) {
    res.cookie("username", req.query["username"]);
    res.redirect("/");
  } else {
    res.status(500).send("Username is required to login");
  }
});

// Clear the cookie when the user logs outs
app.get("/logout", (req, res) => {
  res.clearCookie("username");
  res.redirect("/");
});

app.listen(5000, () => {
  console.log("Web server listening on port 5000");
});