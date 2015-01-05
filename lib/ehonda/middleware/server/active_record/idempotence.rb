module Ehonda
  module Middleware
    module Server
      module ActiveRecord
        class Idempotence
          def initialize logger: Shoryuken.logger
            @logger = logger
          end

          def call _worker, queue, sqs_msg, body
            message = TypedMessage.new sqs_msg

            if ProcessedMessage.exists? message_id: message.id, queue: queue
              @logger.info middleware: 'idempotence', ignored_message_id: message.id
            else
              yield

              ProcessedMessage.create!(
                sqs_id: sqs_msg.message_id,
                message_id: message.id,
                queue: queue,
                message: body)
            end
          end
        end
      end
    end
  end
end
