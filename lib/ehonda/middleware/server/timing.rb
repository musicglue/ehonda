module Ehonda
  module Middleware
    module Server
      class Timing
        include Shoryuken::Util

        def call worker, queue, sqs_msg, body
          started_at = Time.now
          log_data = { queue: queue, worker: worker.class.to_s.underscore }

          begin
            message = TypedMessage.new sqs_msg
            log_data.merge! message_id: message.id, message_type: message.type
          rescue => e
            log_data.merge! sqs_message_id: sqs_msg.id
          end

          logger.info log_data

          begin
            yield
          rescue => e
            error = e
          end

          total_time = elapsed(started_at).round
          visibility_timeout = Shoryuken::Client.queues(queue).visibility_timeout
          excession = total_time - (visibility_timeout * 1000)

          severity = if error
            :error
          elsif excession > 0
            :warn
          else
            :info
          end

          log_data.merge! finished: "#{total_time}ms"
          log_data.merge! exceeded_queue_visible_timeout_by: "#{excession}ms" if excession > 0
          log_data.merge! error: error if error

          logger.send severity, log_data

          raise error if error
        end
      end
    end
  end
end
