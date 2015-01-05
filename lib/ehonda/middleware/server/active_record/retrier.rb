require 'retryable'

module Ehonda
  module Middleware
    module Server
      module ActiveRecord
        class Retrier
          def initialize(options = {})
            @options = { tries: 10, sleep: 0 }.merge options
          end

          def call(&block)
            Retryable.retryable(@options.merge(on: [::ActiveRecord::RecordNotUnique])) do
              Retryable.retryable(@options.merge(matching: /TRDeadlockDetected|TRSerializationFailure/)) do
                yield block
              end
            end
          end
        end
      end
    end
  end
end
