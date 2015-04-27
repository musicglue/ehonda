require 'ehonda/message_sanitizer'

module Ehonda
  class TypedMessage
    def initialize(message)
      @message = message
    end

    def id
      headers['id']
    end

    def type
      headers['type']
    end

    def version
      headers['version']
    end

    def headers
      hash['header']
    end

    def header
      headers
    end

    def body
      hash['body']
    end

    def to_h
      hash
    end

    private

    def convert_active_attr_model_to_hash model
      topic_name = model.class.to_s.underscore.dasherize.sub(/-message$/, '')
      headers = { id: SecureRandom.uuid, type: topic_name, version: 1 }
      attrs = model.respond_to?(:to_h) ? model.to_h : model.attributes

      { header: headers, body: attrs }
    end

    def hash
      @hash ||= begin
        h = if @message.is_a?(TypedMessage)
              @message.to_h
            elsif defined?(::Aws::SQS::Message) && @message.is_a?(::Aws::SQS::Message)
              parse_raw_text @message.body
            elsif defined?(::Shoryuken::Message) && @message.is_a?(::Shoryuken::Message)
              parse_raw_text @message.body
            elsif defined?(::ActiveAttr) && @message.is_a?(::ActiveAttr::Model)
              convert_active_attr_model_to_hash @message
            elsif @message.is_a?(Hash)
              unwrap_non_raw_message_format @message
            else
              parse_raw_text @message
            end

        sanitizer.sanitize(h).with_indifferent_access
      end
    end

    def parse_raw_text raw_text
      unwrap_non_raw_message_format ActiveSupport::JSON.decode(raw_text.to_s)
    end

    def sanitizer
      @sanitizer ||= MessageSanitizer.new
    end

    # if the queue this message was received from was not configured
    # for raw message delivery, we will need to double-decode the
    # actual message body....
    def unwrap_non_raw_message_format hash
      hash = ActiveSupport::JSON.decode(hash['Message']) if hash.key?('Message')
      hash
    end
  end
end
