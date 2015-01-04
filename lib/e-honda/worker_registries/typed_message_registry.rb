require 'e-honda/aws_environmental_name'
require 'e-honda/typed_message'

module EHonda
  module WorkerRegistries
    class TypedMessageRegistry < Shoryuken::WorkerRegistry
      DuplicateSubscriptionError = Class.new StandardError
      InvalidWorkerOptionsError = Class.new StandardError
      UnroutableMessageError = Class.new StandardError
      WorkerNotFoundError = Class.new StandardError

      def initialize dead_letter_queue_name
        @subscriptions = {}
        @dead_letter_queue_name = dead_letter_queue_name
      end

      def batch_receive_messages?(queue)
        false
      end

      def clear
        @subscriptions.clear
      end

      def fetch_worker(queue, message)
        return DeadLetterWorker.new if queue == @dead_letter_queue_name

        queue_subscriptions = @subscriptions.fetch(queue) do
          fail UnroutableMessageError, "#{self} does not know how to route messages for queue '#{queue}'."
        end

        message = TypedMessage.new message
        worker_class = queue_subscriptions[message.type] || queue_subscriptions['*']

        fail WorkerNotFoundError,
          "Worker not found for message type #{message.type} on queue #{queue}." unless worker_class

        worker_class.new
      end

      def queues
        @subscriptions.keys
      end

      def register_worker(queue, clazz)
        workers(queue).each do |worker_class|
          if worker_class.get_shoryuken_options['batch'] == true || clazz.get_shoryuken_options['batch'] == true
            raise ArgumentError, "Could not register #{clazz} for '#{queue}', "\
              "because #{worker_class} is already registered for this queue, "\
              "and Shoryuken doesn't support a batchable worker for a queue with multiple workers"
          end
        end

        worker_subscriptions = clazz.get_shoryuken_options['subscriptions']

        if worker_subscriptions.nil?
          fail InvalidWorkerOptionsError, "Worker #{clazz} must define "\
            "a :subscriptions hash ({ queue_name: message_types }) in "\
            "it's shoryuken_options"
        end

        worker_subscriptions.each do |queue, message_types|
          queue_subscriptions = @subscriptions.fetch_store env_name(queue), {}

          [message_types].flatten.each do |message_type|
            message_type = message_type.to_s.dasherize

            if queue_subscriptions.key? message_type
              fail DuplicateSubscriptionError, "Worker #{clazz} cannot "\
                "define another subscription of message #{message_type} "\
                "on queue #{queue} as it is already subscribed to by "\
                "worker #{queue_subscriptions[message_type]}."
            end

            queue_subscriptions.store message_type, clazz
          end
        end
      end

      def workers(queue)
        @subscriptions.fetch(queue, {}).values
      end

      private

      def env_name(name)
        AwsEnvironmentalName.new(name.to_s).to_s
      end
    end
  end
end
