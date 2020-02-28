import document from "document";
// Import the messaging module
import * as messaging from "messaging";
let spinner = document.getElementById("spinner");

// Start the spinner
spinner.state = "enabled";

import clock from "clock";

let myClock = document.getElementById("myClock");

clock.granularity = 'seconds'; // seconds, minutes, hours

// Updating the time on the clockface
clock.ontick = function(evt) {
  myClock.text = ("0" + evt.date.getHours()).slice(-2) + ":" +
                      ("0" + evt.date.getMinutes()).slice(-2) + ":" +
                      ("0" + evt.date.getSeconds()).slice(-2);
};

// Get the elements & set their values & colors
let eta = document.getElementById("eta");
let teta = document.getElementById("teta");
let weta = document.getElementById("weta");
let ll = document.getElementById("leavelabel");
let tl = document.getElementById("trainlabel");
let wl = document.getElementById("walkinglabel");
let cir = document.getElementById("cir");
messaging.peerSocket.onmessage = function(evt) {
  // Stop the spinner
  spinner.state = "disabled";
  // Adding the text & updating the color of text and arc
  eta.text = evt.data.lT + "min" ;
  ll.text = "Leave in";
  if (evt.data.lT <=3 ) {
    eta.style.fill = "fb-red"
    cir.style.fill = "fb-red"
  } else if (evt.data.lT >3 && evt.data.lT<=5 ) {
    eta.style.fill = "fb-yellow"
    cir.style.fill = "fb-yellow" 
  }
  teta.text = evt.data.tTA + "min" ;
  tl.text = "Train in";
  weta.text = evt.data.wT + "min" ;
  wl.text = "Walk time";
}