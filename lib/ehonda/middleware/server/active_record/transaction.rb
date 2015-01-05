require_relative 'retrier'

module Ehonda
  module Middleware
    module Server
      module ActiveRecord
        class Transaction
          RETRIER_OPTIONS = %i(tries sleep on_retriable_error)
          TRANSACTION_OPTIONS = %i(requires_new joinable isolation)

          def initialize options = {}
            @transaction_options = options.select { |k, _| TRANSACTION_OPTIONS.include? k }
            @retrier_default_options = options.select { |k, _| RETRIER_OPTIONS.include? k }
          end

          def call worker, _queue, _sqs_msg, _body
            Retrier.new(retrier_options(worker)).call do
              ::ActiveRecord::Base.transaction(@transaction_options) do
                yield
              end
            end
          end

          private

          def retrier_options worker
            options = @retrier_default_options.dup
            on_error = options.delete :on_retriable_error
            options[:exception_cb] = worker.method(on_error) unless on_error.to_s.empty?
            options
          end
        end
      end
    end
  end
end
