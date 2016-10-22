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

  # Check if the user provided a login
  token_params = if params[:username]
    # Issue a token request with pub & sub permissions on all channels +
    #   configure the token with an indentity
    {
      capability: { '*' => ['publish', 'subscribe'] },
      client_id: params[:username]
    }
  else
    # Issue a token with subscribe privileges restricted to one channel
    #   and configure the token without an identity (anonymous)
    {
      capability: { 'notifications' => ['subscribe'] }
    }
  end
  ably.auth.create_token_request(token_params).to_json
end
