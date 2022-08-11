require 'ably'

API_KEY = "YOUR_ABLY_API_KEY" # Add your API key here
CLIENT_ID = "my_client_id" # This is who you will appear as in the presence set
raise "Cannot run without an API key. Add your key to example.rb" if API_KEY.include?('INSERT')

puts "Try running this script in multiple consoles concurrently, with a different clientId in each one. Each one will see the others in the presence set."

EventMachine.run do
  # Instance the Ably library
  ably = Ably::Realtime.new(key: API_KEY, client_id: CLIENT_ID)

  # Enter the presence set of the 'chatroom' channel
  channel = ably.channels.get('chatroom')
  channel.attach do
    channel.presence.enter(data: 'hello') do
      puts "We are now in the presence set"
    end

    channel.presence.subscribe do |presence_msg|
      puts "Received a #{presence_msg.action} from #{presence_msg.client_id}"
      channel.presence.get do |members|
        puts "The presence set now consists of " + members.map{ |m| m.client_id }.join(", ")
      end
    end
  end

  puts "Press q<enter> to quit."

  # Run in thread as `gets` is blocking
  Thread.new do
    while true
      case gets.chomp
      when "q"
        # Close the realtime connection explicitly on quitting to avoid the presence member sticking around for 15s; see
        # https://support.ably.io/solution/articles/3000059875-why-don-t-presence-members-leave-as-soon-as-i-close-a-tab-
        ably.close
        EventMachine.stop
      end
    end
  end
end
