class HomeController < ApplicationController
  def index
    if !Rails.application.secrets.ably_api_key
      render text: 'ABLY_API_KEY environment variable missing, please see secrets.yml for config', status: 500
    end
  end
end