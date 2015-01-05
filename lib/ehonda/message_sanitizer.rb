module Ehonda
  class MessageSanitizer
    def sanitize hash
      hash = hash.with_indifferent_access

      {
        header: (hash['headers'] || hash['header']),
        body: hash['body']
      }.with_indifferent_access
    end
  end
end
