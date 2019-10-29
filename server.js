
//setup the express server
var express = require('express');
require('dotenv').config();
var app = express();
app.use(express.json())
var PORT = process.env.PORT || 3000;

app.listen(PORT, function() {
    console.log('Server is running on PORT:',PORT);
});

//setup routes for the index.html file
app.get('/', function(req, res) {
    res.sendFile( __dirname + "/" + "index.html" );
});

//Setup route for static files
app.use(express.static(__dirname + "/" + 'public'));