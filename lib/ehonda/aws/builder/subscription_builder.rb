module Ehonda
  module Aws
    class Builder
      class SubscriptionBuilder
        def initialize logger, queue
          @logger = logger
          @queue = queue
          @arns = Arns.new
          @sns = Ehonda.sns_client
          @sqs = Ehonda.sqs_client
        end

        def build
          queue_url = @sqs.get_queue_url(queue_name: @queue)[:queue_url]

          queue_arn = @sqs.get_queue_attributes(
            queue_url: queue_url,
            attribute_names: ['QueueArn']).attributes['QueueArn']

          topics.each do |topic_name|
            topic_arn = @arns.sns_topic_arn topic_name
            topic = ::Aws::SNS::Topic.new topic_arn, client: @sns

            if Ehonda.configuration.sns_protocol == 'cqs'
              account_id = Ehonda.configuration.aws_account_id

              topic.add_permission(
                label: "subscribe-#{account_id}-#{Time.now.strftime('%Y%m%d%H%M%S')}",
                aws_account_id: [account_id],
                action_name: ['Subscribe'])
            end

            @logger.info subscribing_queue: @queue, subscription_topic: topic_name

            subscription = topic.subscribe(
              endpoint: queue_arn,
              protocol: Ehonda.configuration.sns_protocol)

            subscription.set_attributes attribute_name: 'RawMessageDelivery', attribute_value: 'true'
          end
        end

        private

        def topics
          Shoryuken.worker_registry.topics(@queue)
        end
      end
    end
  end
end
