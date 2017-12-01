var ip = require("ip");
console.log( ip.address() );

//require express
var express = require('express')
    //define app as in instance of express
var app = express()
    //require bosy-parser
var bodyParser = require('body-parser')

//use bodyparser as a middle ware
app.use(bodyParser.json())

//ably realtime
const ably = require('ably').Realtime;
const myably = new ably('Ecaj0g.JZ8Xqg:eX0US8u7zENvxfvA')
const channel = myably.channels.get('cog-tie');



//set cors middleware
app.use((req, res, next)=> {
    res.header("Access-Control-Allow-Origin", "*");
    res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
    next();
});
//handle sending of message via ably
app.post('/send_message', (req, res)=> {
    var message = {
        user: req.body.name,
        msg: req.body.msg,
        action: req.body.action
    }
    channel.publish('message', message, (err)=> {
        if (err) {
            console.log('publish failed with error ' + err);
        } else {
            console.log('publish succeeded ' + message.msg);
        }
    })
    res.send({ status: 'okay', message: message });

});

    //listen on port and serve the app
app.listen(3000, ()=> {
    console.log('Example app listening on port 3000!');
});