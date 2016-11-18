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

  puts "Press <enter> to get the presence set, or q<enter> to stop."

  # Run in thread as `gets` is blocking
  Thread.new do
    while true
      case gets.chomp
      when "q"
        # Close the realtime connection explicitly on quitting to avoid the presence member sticking around for 15s; see
        # https://support.ably.io/solution/articles/3000059875-why-don-t-presence-members-leave-as-soon-as-i-close-a-tab-
        ably.close
        EventMachine.stop
      else
        channel.presence.get do |members|
          puts "There are #{members.length} clients present on this channel"
        end
      end
    end
  end
end
