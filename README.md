# [Ably](https://www.ably.io) Ably WebHook and Chuck Norris Joke API demo

Ably is a hugely scalable, superfast and secure hosted real-time messaging service for web-enabled devices. [Find out more about Ably](https://www.ably.io).

This demo uses realtime pub/sub to publish Chuck Norris joke requests and subscribe to jokes,
and uses the [Ably Reactor Event WebHook](https://www.ably.io/reactor) to deliver messages to a web server in real time.
When the web server app receives joke request, it sends the request to the
[https://api.chucknorris.io/](Chuck Norris Joke API), and publishes the received joke
on a channel so that the browser receives it.

Want to try this demo now? Deploy to Heroku for free:

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/ably/tutorials/tree/webhook-chuck-norris-ruby-rails)

# Setting up the demo on Heroku

Once the app has been deployed to Heroku using the button above, there a few quick steps needed to get this demo running:

* Log in to your Ably dashboard `heroku addons:open ably --app [heroku app name you assigned for this demo]`
* Set up a WebHook with the following settings:
  * URL - `https://[THE HOST NAME FOR THIS APP]/webhook/chuck`
  * Source - choose "Message"
  * Channel Filter - enter `^chuck:ask` to ensure that all Chuck Norris joke requests published to the `chuck:ask` channel are delivered to this app as a WebHook

You are now ready to run the demo: `heroku open --app [heroku app name you assigned for this demo]`

# Ably Reactor

The Ably Reactor provides Queues to consume realtime data, Events to trigger server-side code or functions in respons to realtime data, and Firehose to stream events to other queue or streaming services.

[Find out more about the Ably Reactor](https://www.ably.io/reactor)

# Questions

Please visit http://support.ably.io/ for access to our knowledgebase and to ask for any assistance.

# License

Copyright (c) 2017 Ably Real-time Ltd, Licensed under the Apache License, Version 2.0. Refer to [LICENSE](./LICENSE) for the license terms.