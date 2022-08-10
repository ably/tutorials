const express = require("express");
const jwt = require("jsonwebtoken");

const app = express();

// Serve all HTML & CSS assets from root folder
app.use("/", express.static(__dirname));

// You will need to create a .env file that contains your API key
require("dotenv").config();

const apiKey = process.env.ABLY_API_KEY;
const [keyid, keySecret] = apiKey.split(":");

const expiresIn = 3600;
const capability = JSON.stringify({ "*": ["publish", "subscribe"] });
const jwtOptions = { expiresIn, keyid };

// Handle requests to our auth endpoint
app.get("/auth", (req, res) => {
  console.log("Sucessfully connected to the server auth endpoint");

  // Normally we would validate the user before issuing the JWT token
  // but for simplicity we'll just use their input as the `clientId`

  const randomId = Math.random().toString(16).slice(-8);
  const clientId = req.query.clientId || randomId;

  const jwtPayload = {
    "x-ably-capability": capability,
    "x-ably-clientId": clientId,
  };

  jwt.sign(jwtPayload, keySecret, jwtOptions, (err, tokenId) => {
    console.log("✓ JSON Web Token signed by auth server");
    console.log(": ClientId: [%s]\n\n", clientId);

    if (err) return console.trace();

    res.header("Cache-Control", "private, no-cache, no-store, must-revalidate");
    res.setHeader("Content-Type", "application/json");

    console.log(": Sending signed JWT token back to client:\n%s", tokenId);
    res.send(JSON.stringify(tokenId));
  });
});

app.listen(3000, () => {
  console.log("✓ Web server listening on port", 3000);
  console.log(": Ably API key parts:", keyid, keySecret, "\n\n");
});
