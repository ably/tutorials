require 'pusher'

API_KEY = "INSERT-API-KEY-HERE" # Add your API key here
raise "Cannot run without an API key. Add your key to example.rb" if API_KEY.include?('INSERT')

APP_ID = API_KEY.split('.')[0]
KEY_NAME, KEY_SECRET = API_KEY.split(':')

Pusher::Client.new(
  app_id:    APP_ID,
  key:       KEY_NAME,
  secret:    KEY_SECRET,
  host:      'rest-pusher.ably.io',
  encrypted: true
)
