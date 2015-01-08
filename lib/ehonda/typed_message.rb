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
        body = JSON.parse(@message.body)

        if body.key?('Message')
          JSON.parse(body['Message'])
        else
          body
        end
      end
    end
  end
end
