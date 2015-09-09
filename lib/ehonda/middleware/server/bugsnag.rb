module Ehonda
  module Middleware
    module Server
      class Bugsnag
        def call(_worker, _queue, sqs_msg, body)
          yield
        rescue => e
          parameters = {}

          begin
            message = TypedMessage.new sqs_msg
            parameters.store :message, message.headers
          rescue
            parameters.store :unknown_message_format, body
          end

          ::Bugsnag.notify e, parameters: parameters

          raise e
        end
      end
    end
  end
end
