
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


const LanguageTranslatorV3 = require('ibm-watson/language-translator/v3');
const { IamAuthenticator } = require('ibm-watson/auth');

//create an instance of the language translator.
const languageTranslator = new LanguageTranslatorV3({
  version: '{version}',
  authenticator: new IamAuthenticator({
    apikey: '{apikey}',
  }),
  url: '{url}',
});


//This endpoint translates the text send to it  
app.post('/api/translate', function(req, res, next) {
    translator.translate(req.body)
    .then(data => res.json(data.result))
    .catch(error => next(error));
});


  //This endpoint gets all the langauges that can be processed by the translator
app.get('/api/get-languages', function(req, res, next) {
    translator.listIdentifiableLanguages()
    .then(identifiedLanguages => {
        res.json(identifiedLanguages.result);
    })
    .catch(err => {
        console.log('error:', err);
    });
})


  //This endpoint gets all the model list.
app.get('/api/get-model-list', function(req, res, next) {
    translator.listModels()
    .then(translationModels => {
        res.json(translationModels.result)
    })
    .catch(err => {
        console.log('error:', err);
    });
})