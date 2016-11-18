require 'ably'

API_KEY = "INSERT-API-KEY-HERE" # Add your API key here
CLIENT_ID = "my_client_id" # This is who you will appear as in the presence set
raise "Cannot run without an API key. Add your key to example.rb" if API_KEY.include?('INSERT')

EventMachine.run do
  # Instance the Ably library
  ably = Ably::Realtime.new(key: API_KEY, client_id: CLIENT_ID)

  # Enter the presence set of the 'chatroom' channel
  channel = ably.channels.get('chatroom')
  channel.attach do
    channel.presence.enter(data: 'hello') do
      puts "We are now in the presence set"
    end
  end
end
