require 'ably'
require 'pubnub'

API_KEY = "INSERT-API-KEY-HERE" # Add your API key here
raise "Cannot run without an API key. Add your key to example.rb" if API_KEY.include?('INSERT')
channel_name = 'some_channel'

EventMachine.run do
  # ABLY CLIENT LIB
  # Instance the Ably library
  ably = Ably::Realtime.new(key: API_KEY)

  # Subscribe to the 'some_channel' channel with the Ably client
  ablyChannel = ably.channels.get(channel_name)
  ablyChannel.subscribe do |message|
    puts "Ably client received a message: #{message.data.inspect}"
  end

  # PUBNUB CLIENT LIB
  # Instance the Pubnub library
  pubnub = Pubnub.new(
    :subscribe_key => API_KEY,
    :publish_key   => API_KEY,
    :origin        => 'pubnub.ably.io',
    :ssl           => true
  )

  # Subscribe to the 'some_channel' channel with the Pubnub client
  pubnub.subscribe(
    channel: channel_name,
  ) do |env|
    puts "Pubnub client received a message: #{env.message.inspect}"
  end

  puts "Press p<enter> to publish a message with the Pubnub client library, a<enter> to publish with the Ably client library. Press q<enter> to quit."

  # Run in thread as `gets` is blocking
  Thread.new do
    while true
      case gets.chomp
      when "a"
        ablyChannel.publish(nil, { some: 'data sent by the Ably client library' })
      when "p"
        pubnub.publish(channel: channel_name, message: { some: 'data sent by the Pubnub client library' }) {}
      when "q"
        ably.close
        EventMachine.stop
      end
    end
  end
end
