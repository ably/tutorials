require 'pusher'
require 'ably'

API_KEY = "INSERT-API-KEY-HERE" # Add your API key here
raise "Cannot run without an API key. Add your key to example.rb" if API_KEY.include?('INSERT')

APP_ID = API_KEY.split('.')[0]
KEY_NAME, KEY_SECRET = API_KEY.split(':')

pusher_channel_name = 'some_channel'
ably_channel_name = 'public:some_channel'

EventMachine.run do
  # ABLY CLIENT LIB
  # Instance the Ably library
  ably = Ably::Realtime.new(key: API_KEY, log_level: :info)

  # Subscribe to the 'public:some_channel' channel with the Ably client
  ablyChannel = ably.channels.get(ably_channel_name)
  ablyChannel.subscribe do |message|
    puts "Ably client received a message: #{message.name} - #{message.data.inspect}"
  end

  # PUSHER CLIENT LIB
  # Instance the Pusher library
  pusher = Pusher::Client.new(
    app_id:    APP_ID,
    key:       KEY_NAME,
    secret:    KEY_SECRET,
    host:      'rest-pusher.ably.io',
    encrypted: true
  )

  puts "Press p<enter> to publish a message with the Pusher client library, and see it be received by the Ably client library. Press q<enter> to quit."

  # Run in thread as `gets` is blocking
  Thread.new do
    while true
      case gets.chomp
      when "p"
        pusher.trigger(pusher_channel_name, 'event_name', {some: 'data sent by the Pusher client library'})
      when "q"
        ably.close
        EventMachine.stop
      end
    end
  end
end
