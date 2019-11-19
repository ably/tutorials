var mqtt = require('mqtt')
var options = {
    keepalive: 30,
    username: '<FIRST-HALF-OF-YOUR-ABLY-API-KEY>',
    password: '<SECOND-HALF-OF-YOUR-ABLY-API-KEY>',
    port: 8883
};

var client = mqtt.connect('mqtts:mqtt.ably.io', options);
client.on('connect', () => {
    //subscribe to the channel streaming the weather data for London, UK
    client.subscribe('[product:ably-openweathermap/weather?rewind=2]weather:2643741')
});

client.on('message', (topic, message) => {
    var msg = JSON.parse(message)
    console.log((msg.main.temp - 273.15).toFixed(2) + '°C with ' + msg.weather[0].description)
});

client.on('error', (topic, message) => {
    console.log(message.toString())
});