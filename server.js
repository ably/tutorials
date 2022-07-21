const jwt = require("jsonwebtoken");
require("dotenv").config();

/*

  You need to create a .env file that contains your API key
  To create a free account see: https://ably.com/signup

*/

const port = process.env.PORT || 3000;
const ablyApiKey = process.env.ABLY_API_KEY;
const [appId, keyId, keySecret] = ablyApiKey.split(/[\.:]/g);

const expiresIn = 3600; // 30 seconds
const capability = JSON.stringify({ "*": ["publish", "subscribe"] });

const keyid = `${appId}.${keyId}`;
const clientId = "OPTIONAL_CLIENT_ID";

const jwtPayload = {
  "x-ably-capability": capability,
  "x-ably-clientId": clientId,
};

const jwtOptions = { expiresIn, keyid };

const express = require("express");
const app = express();

// Serve all HTML & CSS assets from root folder
app.use("/", express.static(__dirname));

// Handle specific requests to our auth endpoint
app.get("/auth", (req, res) => {
  console.log("Sucessfully connected to the server auth endpoint");
  jwt.sign(jwtPayload, keySecret, jwtOptions, (err, tokenId) => {
    console.log("JSON Web Token signed by auth server");

    if (err) return console.trace();

    res.header("Cache-Control", "private, no-cache, no-store, must-revalidate");
    res.setHeader("Content-Type", "application/json");

    console.log("Sending signed JWT token back to client", tokenId);
    res.send(JSON.stringify(tokenId));
  });
});

app.listen(3000, () => {
  console.log("Web server listening on port ", port);
  console.log("Ably API key parts:", appId, keyId, keySecret);
});
