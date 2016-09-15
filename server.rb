require 'ably'
require 'json'
require 'sinatra'
require 'sinatra/cookies'

API_KEY = "INSERT-API-KEY-HERE" # Add your API key here
raise "Cannot run without an API key. Add your key to example.rb" if API_KEY.include?('INSERT')

# Instance the Ably server REST library
ably = Ably::Rest.new(key: API_KEY)

# Allow cookies to be read in the browser
set :cookie_options, httponly: false

get '/' do
  File.read('index.html')
end

# Issue token requests to clients sending a request to the /auth endpoint
get '/auth' do
  content_type :json

  # Check if the user is logged in
  token_params = if cookies[:username]
    # Issue a token request with pub & sub permissions on all channels +
    #   configure the token with an indentity
    {
      capability: { '*' => ['publish', 'subscribe'] },
      client_id: cookies[:username]
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

# Set a cookie when the user logs in
get '/login' do
  # Login the user without credentials.
  # This is an over simplified authentication system
  # to keep this tutorial simple
  if request.params['username']
    cookies[:username] = request.params['username']
    redirect to('/')
  else
    status 500
    'Username is required to login'
  end
end

# Clear the cookie when the user logs outs
get '/logout' do
  cookies.delete 'username'
  redirect to('/')
end
