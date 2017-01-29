class AuthController < ApplicationController
  # Realtime (browser) clients send an HTTP request using authUrl to this endpoint to get a token
  # This action issues an anonymous tokenRequest with all capabilities
  #   Note: Not restricing capabilities is an anti-pattern: see https://en.wikipedia.org/wiki/Principle_of_least_privilege
  def issue_token_request
    render json: ably_rest.auth.create_token_request
  end
end