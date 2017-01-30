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
          if message.data.strip.empty?
            get_random_joke
          else
            find_matching_jokes message.data
          end
        end
      end
      render json: { "success": true }
    else
      render json: { "error": "items Array attribute missing from body" }, status: :unprocessable_entity
    end
  end

  private
  def get_random_joke
    chuck_request_started = Time.now.to_f
    response = JSON.parse(HTTP.get('https://api.chucknorris.io/jokes/random').to_s)
    publish_joke response['value'], Time.now.to_f - chuck_request_started
  end

  def find_matching_jokes(text)
    chuck_request_started = Time.now.to_f
    response = JSON.parse(HTTP.get("https://api.chucknorris.io/jokes/search?query=#{CGI::escape(text)}").to_s)
    if response['result']
      response['result'].first(3).each do |joke|
        publish_joke joke['value'], Time.now.to_f - chuck_request_started
      end
    else
      publish_joke "No Chuck joke matching text '#{text}'", Time.now.to_f - chuck_request_started
    end
  end

  def publish_joke(joke, chuck_time)
    ably_rest.channels.get('chuck:jokes').publish('joke', { joke: joke, chuckTime: (chuck_time * 1000).to_i })
  end
end