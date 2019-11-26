
[![Ably](https://s3.amazonaws.com/files.ably.io/logo-with-type.png)](https://www.ably.io)

# Tutorials repository

This repository contains the working code for many of the [Ably tutorials](https://www.ably.io/tutorials).

See [https://www.ably.io/tutorials](https://www.ably.io/tutorials) for a complete list of Ably tutorials. The source code for each tutorial exists as a branch in this repo, see [the complete list of tutorial branches in this repository](https://github.com/ably/tutorials/branches/all).

To find out more Ably and our realtime data delivery platform, visit [https://www.ably.io](https://www.ably.io)

This branch contains the starter kit for the flight tracking tutorial built in React, using the Heathrow flights data stream on the Ably Hub.

## Developer Guide

The starter is designed with [Expo Managed Workflow](http://expo.io) to make getting started with Ably's API Streamer using React Native easy. Developer is expected to have basic knowledege of JavaScript, React, and React Native to work effectively with this kit.

### Installation

Please ensure you have the following installed before you get started with this kit:

- **Node.js**
[nodejs](https://nodejs.org)

- **Yarn**
`npm install -g yarn`

- **Expo CLI**
`npm install -g expo-cli`

### Running the application

#### Step one - Clone the project and navigate in local machine (Clone don't fork)

```shell
git clone  https://github.com/ably/tutorials/tree/flight-tracking-app-starter-kit.git
```

```shell
cd flight-tracking-app-starter-kit
```

#### Step Two - Start the project

> NB: If you don't have `expo-cli` Please, do so before proceeding
**start**

```shell
expo start
```
> NB: The script should dynamically open your default broswer

**build**

```shell
expo build
```

You can quickly follow up the tutorial [here](https://dev.to/ablydev) to build your own live flight tracking application