Rails.application.routes.draw do
  get '/auth' => 'auth#issue_token_request'
  root to: 'home#index'
end
