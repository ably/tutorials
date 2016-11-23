require 'pubnub'

API_KEY = "INSERT-API-KEY-HERE" # Add your API key here
raise "Cannot run without an API key. Add your key to example.rb" if API_KEY.include?('INSERT')

# Instance the Pubnub library
pubnub = Pubnub.new(
  :subscribe_key => API_KEY,
  :publish_key   => API_KEY,
  :origin        => 'pubnub.ably.io',
  :ssl           => true
)
