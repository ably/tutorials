require 'ably'
require 'json'
require 'sinatra'

API_KEY = "INSERT-API-KEY-HERE" # Add your API key here
raise "Cannot run without an API key. Add your key to example.rb" if API_KEY.include?('INSERT')

# Instance the Ably server REST library
ably = Ably::Rest.new(key: API_KEY)

get '/' do
  'Hello, I am a very simple server'
end

# Issue token requests to clients sending a request to the /auth endpoint
get '/auth' do
  content_type :json
  ably.auth.create_token_request.to_json
end
