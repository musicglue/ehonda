module Ehonda
  class MessageSanitizer
    InvalidMessageError = Class.new StandardError

    def sanitize hash
      hash = hash.with_indifferent_access
      header = hash['headers'] || hash['header']
      body = hash['body']

      invalid_message = !header.is_a?(Hash) || header.empty? || !body.is_a?(Hash) 

      fail InvalidMessageError, 'MessageSanitizer expected a hash with non-empty '\
                                "'header' and 'body' keys, but received #{hash}." if invalid_message

      {
        header: header,
        body: body
      }.with_indifferent_access
    end
  end
end
