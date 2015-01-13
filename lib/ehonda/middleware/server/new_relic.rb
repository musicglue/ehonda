require 'new_relic/agent/instrumentation/controller_instrumentation'

module Ehonda
  module Middleware
    module Server
      class NewRelic
        include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation

        def call(worker, queue, sqs_msg, body)
          trace_args = if worker.respond_to?(:newrelic_trace_args)
            worker.newrelic_trace_args(worker, queue, sqs_msg)
          else
            self.class.default_trace_args(worker, queue, sqs_msg)
          end

          perform_action_with_newrelic_trace(trace_args) do
            if ::NewRelic::Agent.config[:'shoryuken.capture_params']
              ::NewRelic::Agent.add_custom_parameters(
                message_attributes: sqs_msg.message_attributes,
                message_body: sqs_msg.body)
            end

            yield
          end
        end

        private

        def self.default_trace_args(worker, queue, sqs_msg)
          {
            name: 'perform',
            class_name: worker.class,
            category: 'OtherTransaction/ShoryukenJob',
            params: { queue: queue }
          }
        end
      end
    end
  end
end


