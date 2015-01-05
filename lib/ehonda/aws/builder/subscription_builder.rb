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

          topics.each do |topic|
            topic = EnvironmentalName.new(topic).to_s
            topic_arn = @arns.sns_topic_arn topic

            if Ehonda.configuration.sns_protocol == 'cqs'
              account_id = Ehonda.configuration.aws_account_id
              label = "subscribe-#{account_id}-#{Time.now.strftime('%Y%m%d%H%M%S')}"

              @sns.add_permission topic_arn: topic_arn,
                                  label: label,
                                  aws_account_id: [account_id],
                                  action_name: ['Subscribe']
            end

            @logger.info subscribing_queue: @queue, subscription_topic: topic

            @sns.subscribe(
              endpoint: queue_arn,
              protocol: Ehonda.configuration.sns_protocol,
              topic_arn: topic_arn)
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
