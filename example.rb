require 'ably'

API_KEY = "INSERT-API-KEY-HERE" # Add your API key here
raise "Cannot run without an API key. Add your key to example.rb" if API_KEY.include?('INSERT')

puts <<-EOF
Run this script in multiple consoles concurrently.
Each script will simultaneously receive the published message as all clients are subscribed to the "sport" channel.
EOF

EventMachine.run do
  # Instance the Ably library
  ably = Ably::Realtime.new(key: API_KEY)

  # Subscribe to messages on the sport channel
  channel = ably.channels.get('sport')
  channel.subscribe do |msg|
    puts "Received: #{msg.data}"
  end

  # Publish a message when enter is pressed
  puts "Press <enter> to publish a message. Use <ctrl>-c to stop."

  # Run in thread as `gets` is blocking
  Thread.new do
    while true
      gets
      channel.publish 'update', 'team' => 'Man United'
    end
  end
end
