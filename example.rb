require 'ably'

API_KEY = "INSERT-API-KEY-HERE" # Add your API key here
raise "Cannot run without an API key. Add your key to example.rb" if API_KEY.include?('INSERT')

EventMachine.run do
  # Instance the Ably library
  ably = Ably::Realtime.new(key: API_KEY)

  # Subscribe to messages on the sport channel
  channel = ably.channels.get('sport')
  channel.subscribe do |msg|
    puts "Received: #{msg.data}"
  end
end
