# Realtime Multilingual Chat App

### Context
This repository consists of the code for a realtime multilingual chat app. This app enables people to chat in different languages. It uses the IBM-Watson Language Translator API for the translation of languages and Ably Pub/Sub for realtime sharing of messages.

The app consists three parts:
<ul>
  <li>A dropdown that the users can use to select the preferred language that they want to communicate in.</li>
  <li>The chat section where messages in the chat channel will appear. </li>
  <li>The input section where users can add messages to the chat conversation. </li>
</ul>

### Requirements
To get this app running on your system, ensure that you are working with Node >= version 6 and npm >= version 5.2.

### Getting Started
Here are the steps to get this app running on your system.
<ol>  
  <li>Clone or download this app</li>
  <li>Run `npm install`</li>
  <li>In the `index.js` file, replace "YOUR_ABLY_API_KEY" on line 142 with your APP ID gotten from your Ably dashboard. Also, in the `server.js` file, replace the IBM-Watson credentials with the right credentials.</li>
  <li>Run `npm start`</li>
</ol>

### More Information
To find out more Ably and our realtime data delivery platform, visit [https://www.ably.io](https://www.ably.io)

