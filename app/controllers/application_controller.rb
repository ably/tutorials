class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  private
  def ably_rest
    @ably_rest ||= Ably::Rest.new(key: Rails.application.secrets.ably_api_key)
  end
end
