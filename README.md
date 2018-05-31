[![Ably](https://s3.amazonaws.com/files.ably.io/logo-with-type.png)](https://www.ably.io)

This tutorial is built using:

* [A-Frame](http://aframe.io/), a web framework for building virtual reality experiences. Make WebVR with HTML and Entity-Component. Works on Vive, Rift, desktop, mobile platforms.

* Ably Realtime, a realtime data delivery platform providing developers everything they need to create, deliver and manage complex projects.

# Steps to get it working

## On Glitch

* Paste all these files on a [Glitch](https://glitch.com) project.
* Replace the placeholder text in server.js with your Ably API key.
* If you don't already have an account, create a free one, [here](ably.io).
* Hit 'See Live' and open up this URL in two different browser windows.
* NOTE: The limits for an Ably free account allow you to have a maximum of two instances of the app running at any time. If you wish to have more instances running, have a look at the Ably [self-service package](https://www.ably.io/pricing/self-service) and buy messages accordingly. 

## On local machine

* Clone this repo.
* Replace the placeholder text in server.js with your Ably API key.
* If you don't already have an account, create a free one, [here](ably.io).
* Run 'npm install' to install express, ably and cookie-parser npm modules that are used in the app.
* Run 'node server.js' to start the server.
* Open up two browser windows and visit 'http://localhost:3000/'
* NOTE: The limits for an Ably free account allow you to have a maximum of two instances of the app running at any time. If you wish to have more instances running, have a look at the Ably [self-service package](https://www.ably.io/pricing/self-service) and buy messages accordingly. 