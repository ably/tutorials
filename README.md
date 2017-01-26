# [Ably](https://www.ably.io) Ably Reactor Queue and Neutrino Profanity Filter demo

Ably is a hugely scalable, superfast and secure hosted real-time messaging service for web-enabled devices. [Find out more about Ably](https://www.ably.io).

This demo uses realtime pub/sub to publish unfiltered text and subscribe to filtered text (without profanities), and uses the [Ably Reactor Queues](https://www.ably.io/reactor) to subscribe to realtime data from a worker server over AMQP. When the worker receives unfiltered text, it sends the request to the <a href="https://www.neutrinoapi.com/api/bad-word-filter/">Neutrino Bad Word Filter API</a> to filter out profanities, and publishes the filtered text on a channel so that the browser receives it.

Want to try this demo now? Deploy to Heroku for free:

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/ably/tutorials/tree/queue-neutrino-profanity-nodejs)

# Setting up the demo on Heroku

Once the app has been deployed to Heroku using the button above, there a few quick steps needed to get this demo running:

* [Sign up for a free Developer Account with Neutrino](https://www.neutrinoapi.com/signup/)
* Configure two environment variables in Heroku with your Neutrino credentials:
  * `NEUTRINO_USER_ID` needs to contain your Neutrino user ID: `heroku config:set NEUTRINO_USER_ID=[your Neutrino user id] --app [heroku app name you assigned for this demo]`
  * `NEUTRINO_API_KEY` needs to contain your Neutrino user ID: `heroku config:set NEUTRINO_API_KEY=[your Neutrino user id] --app [heroku app name you assigned for this demo]`
* Log in to your Ably dashboard `heroku addons:open ably --app [heroku app name you assigned for this demo]`
* Set up a queue (in the Queues tab) with the name `neutrino` in the `US East (Virgina)` area.
* Set up a queue rule (button to add rules is further down the page within the Queues tab) with the following:
  * Queue - choose the `neutrino` queue you just set up
  * Source - choose "Message"
  * Channel Filter - enter `"^neutrino:raw"` to ensure that all questions published to the `neutrino:raw` channel are republished into the `neutrino` queue

You are now ready to run the demo: `heroku open --app [heroku app name you assigned for this demo]`

# Ably Reactor

The Ably Reactor provides Queues to consume realtime data, Events to trigger server-side code or functions in respons to realtime data, and Firehose to stream events to other queue or streaming services.

[Find out more about the Ably Reactor](https://www.ably.io/reactor)

# Questions

Please visit http://support.ably.io/ for access to our knowledgebase and to ask for any assistance.

# License

Copyright (c) 2017 Ably Real-time Ltd, Licensed under the Apache License, Version 2.0. Refer to [LICENSE](./LICENSE) for the license terms.
