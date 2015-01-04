module EHonda
  class TypedMessage
    def initialize message
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

    def body
      hash['body']
    end

    private

    def hash
      @hash ||= JSON.parse(@message.body)
    end

    def headers
      hash['header']
    end
  end
end
