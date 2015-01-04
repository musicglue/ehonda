module EHonda
  module Middleware
    module Server
      class Airbrake
        def call(worker, queue, sqs_msg, body)
          yield
        rescue => e
          parameters = {}

          begin
            message = TypedMessage.new sqs_msg
            parameters.store :message, message.headers
          rescue
            parameters.store :unknown_message_format, body
          end

          ::Airbrake.notify_or_ignore e, parameters: parameters

          raise e
        end
      end
    end
  end
end
