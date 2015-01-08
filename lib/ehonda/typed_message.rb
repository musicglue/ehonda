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
      hash['headers'] || hash['header']
    end

    def body
      hash['body']
    end

    def to_h
      hash
    end

    private

    def hash
      @hash ||= begin
        if @message.is_a?(TypedMessage)
          @message.to_h
        else
          raw_text = @message
          raw_text = @message.body if @message.is_a?(::Aws::SQS::Message)

          parsed = JSON.parse(raw_text)

          # cmb uses a different serialization format to aws, so we do some
          # format detection to see if we need to do more processing to get
          # the message hash out
          parsed = JSON.parse(parsed['Message']) if parsed.key?('Message')
          parsed.with_indifferent_access
        end
      end
    end
  end
end
