Rails.application.routes.draw do
  get '/auth' => 'auth#issue_token_request'
  post '/webhook/chuck' => 'webhook#chuck_request', format: :json
  root to: 'home#index'
end
