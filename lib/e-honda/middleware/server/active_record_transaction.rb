module EHonda
  module Middleware
    module Server
      class ActiveRecordTransaction
        def call(worker, queue, sqs_msg, body)
          options = worker_class.get_shoryuken_options['active_record_transaction']
          @callback = options.delete :on_serialization_failure

          ::ActiveRecord::Base.transaction(options) do
            yield
          end
        rescue ::ActiveRecord::StatementInvalid => error
          raise error unless error.message =~ /PG::TRSerializationFailure/
          worker.send(@callback) if @callback && worker.respond_to?(@callback)
          retry
        end
      end
    end
  end
end
