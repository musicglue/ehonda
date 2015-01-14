module Ehonda
  class MessageSanitizer
    InvalidMessageError = Class.new StandardError

    def sanitize hash
      hash = hash.with_indifferent_access

      header = hash['headers'] || hash['header']
      body = hash['body']

      fail InvalidMessageError, "MessageSanitizer expected a hash with non-empty "\
                                "'header' and 'body' keys, but received #{hash}." if (header.empty? || body.empty?)

      {
        header: header,
        body: body
      }.with_indifferent_access
    end
  end
end
