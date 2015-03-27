require_relative 'arns'
require_relative 'environmental_name'
require_relative 'builder/application_policy_builder'
require_relative 'builder/queue_builder'
require_relative 'builder/subscription_builder'
require_relative 'builder/topic_builder'

module Ehonda
  module Aws
    class Builder
      def initialize logger = nil
        @logger = logger || Shoryuken::Logging.logger
      end

      def build_policies
        ApplicationPolicyBuilder.new(@logger).build
      end

      def build_queues
        Shoryuken.worker_registry.queues.each do |queue|
          QueueBuilder.new(@logger, queue).build
        end
      end

      def build_topics
        (Shoryuken.worker_registry.topics + Ehonda.configuration.published_topics).uniq.sort.each do |topic|
          TopicBuilder.new(@logger, topic).build
        end
      end

      def build_subscriptions
        Shoryuken.worker_registry.queues.each do |queue|
          SubscriptionBuilder.new(@logger, queue).build
        end
      end

      def delete_all
        Shoryuken.worker_registry.queues.each do |queue|
          QueueBuilder.new(@logger, queue).delete
        end

        Shoryuken.worker_registry.topics.each do |topics|
          TopicBuilder.new(@logger, topics).delete
        end
      end
    end
  end
end
