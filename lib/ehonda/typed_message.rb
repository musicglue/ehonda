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

      { header: headers, body: model.attributes }
    end

    def hash
      @hash ||= begin
        h = if @message.is_a?(TypedMessage)
              @message.to_h
            elsif defined?(::ActiveAttr) && @message.is_a?(::ActiveAttr::Model)
              convert_active_attr_model_to_hash @message
            elsif @message.is_a?(Hash)
              unwrap_non_raw_message_format @message
            else
              raw_text = @message

              parsed = ActiveSupport::JSON.decode(raw_text.to_s)
              parsed = ActiveSupport::JSON.decode(parsed['Message']) if parsed.key?('Message')

              unwrap_non_raw_message_format parsed
            end

        sanitizer.sanitize(h).with_indifferent_access
      end
    end

    # if the queue this message was received from was not configured
    # for raw message delivery, we will need to double-decode the
    # actual message body....
    def unwrap_non_raw_message_format hash
      hash = ActiveSupport::JSON.decode(hash['Message']) if hash.key?('Message')
      hash
    end

    def sanitizer
      @sanitizer ||= MessageSanitizer.new
    end
  end
end
