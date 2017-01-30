class WebhookController < ApplicationController
  # Incoming WebHooks don't come from this web application so will not have an
  # authentication token from this web application
  skip_before_action :verify_authenticity_token

  def chuck_request
    body = JSON.parse(request.body.read)

    # WebHook messages are sent in items.data.messages, see https://goo.gl/WT9DnH
    if body["items"] && body["items"].kind_of?(Array)
      body["items"].each do |item|
        Array(item.dig('data', 'messages')).each do |message_raw|
          # Use Ably to parse messages from JSON so that all encoding issues are resolved automatically
          message = Ably::Models::Message.from_json(message_raw)
          puts "Received Message with data '#{message.data}'"
        end
      end
      render json: { "success": true }
    else
      render json: { "error": "items Array attribute missing from body" }, status: :unprocessable_entity
    end
  end
end