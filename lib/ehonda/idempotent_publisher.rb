module Ehonda
  class IdempotentPublisher
    def initialize limit: 100, publisher_client: nil, logger: nil
      @limit = limit
      @publisher_id = ENV['DYNO'] || 'publisher'
      @publisher = publisher_client
      @logger = logger || Shoryuken.logger
    end

    def publish
      timestamp = Time.now

      PublishedMessage.unsent.limit(@limit).update_all(
        published_by: @publisher_id,
        attempted_at: timestamp)

      messages = PublishedMessage.sent_by(@publisher_id, timestamp)
      messages.update_all 'attempts = attempts + 1'

      messages.each do |message|
        begin
          response = publisher.publish message.message
          message.update! response: response.data.to_hash, published_at: Time.now
        rescue => e
          @logger.error({ component: 'idempotent_publisher', state: 'publish' }, e)
          message.update! response: { error: e.to_s }
        end
      end

      messages.reload
    end

    private

    def publisher
      @publisher ||= begin
        require 'ehonda/message_publisher'
        MessagePublisher.new
      end
    end
  end
end
