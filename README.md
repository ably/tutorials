# [Ably](https://www.ably.io) Ably Reactor Queue and Wolfram Alpha demo

Ably is a hugely scalable, superfast and secure hosted real-time messaging service for web-enabled devices. [Find out more about Ably](https://www.ably.io).

This demo uses realtime pub/sub to publish questions and subscribe to answers, and uses the [Ably Reactor Queues](https://www.ably.io/reactor) to subscribe to realtime data from a worker server over AMQP. When the worker receives a question, it sends the request to Wolfram Alpha to get the answer, and publishes the answer on a channel so that the browser receives it.

Want to try this demo now? Deploy to Heroku for free:

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/ably/tutorials/tree/queue-wolfram-alpha-nodejs)

# Setting up the demo on Heroku

Once the app has been deployed to Heroku using the button above, there a few quick steps needed to get this demo running:

* [Sign up for a free Developer AppId with Wolfram Alpha](http://developer.wolframalpha.com/)
* Configure an environment variable with the Wolfram AppId (replace `[your wolfram app id]` with the AppId from the previous step): `heroku config:set WOLFRAM_APP_ID=[your wolfram app id] --app [heroku app name you assigned for this demo]`
* Log in to your Ably dashboard `heroku addons:open ably --app [heroku app name you assigned for this demo]`
* Set up a queue (in the Queues tab) with the name `wolfram` in the `US East (Virgina)` area.
* Set up a queue rule (button to add rules is further down the page within the Queues tab) with the following:
  * Queue - choose the `wolfram` queue you just set up
  * Source - choose "Message"
  * Channel Filter - enter `"^wolfram:questions"` to ensure that all questions published to the `wolfram:questions` channel are republished into the `wolfram` queue

You are now ready to run the demo: `heroku open --app [heroku app name you assigned for this demo]`

# Ably Reactor

The Ably Reactor provides Queues to consume realtime data, Events to trigger server-side code or functions in respons to realtime data, and Firehose to stream events to other queue or streaming services.

[Find out more about the Ably Reactor](https://www.ably.io/reactor)

# Questions

Please visit http://support.ably.io/ for access to our knowledgebase and to ask for any assistance.

# License

Copyright (c) 2017 Ably Real-time Ltd, Licensed under the Apache License, Version 2.0. Refer to [LICENSE](./LICENSE) for the license terms.
