module Ehonda
  module DeadLetters
    class Retrier
      def initialize logger = nil
        @logger = logger || Shoryuken.logger
      end

      def retry scope
        return if scope.count == 0

        count = 0
        scope.each do |message|
          count += 1
          publisher.publish message.message
          message.delete
        end

        @logger.info "Retried #{count} dead letter(s)."
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
end
