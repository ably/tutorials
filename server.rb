require 'ably'
require 'sinatra'

API_KEY = "INSERT-API-KEY-HERE" # Add your API key here
raise "Cannot run without an API key. Add your key to example.rb" if API_KEY.include?('INSERT')

# Instance the Ably server REST library
ably = Ably::Rest.new(key: API_KEY)

get '/' do
  'Hello, I am a very simple server'
end
