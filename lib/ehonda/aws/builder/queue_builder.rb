module Ehonda
  module Aws
    class Builder
      class QueueBuilder
        def initialize logger, name
          @logger = logger
          @name = name
          @arns = Arns.new
          @sqs = Ehonda.sqs_client
        end

        def build
          @logger.info building_queue: @name

          queue_url = @sqs.create_queue(queue_name: @name)[:queue_url]
          queue = Aws::SQS::Queue.new queue_url, @sqs
          queue_configuration = Ehonda.configuration.get_queue(@name)

          attributes = {
            'DelaySeconds' => queue_configuration.delay_seconds.to_s,
            'MessageRetentionPeriod' => queue_configuration.message_retention_period.to_s,
            'VisibilityTimeout' => queue_configuration.visibility_timeout.to_s
          }

          if Ehonda.configuration.sqs_protocol == 'sqs'
            if queue_configuration.respond_to?(:redrive_policy)
              policy = redrive_policy(
                queue_configuration.redrive_policy.dead_letter_queue,
                queue_configuration.redrive_policy.max_receive_count) if queue_configuration.redrive_policy.enabled

              attributes.merge! 'RedrivePolicy' => policy.to_s
            end

            policy = queue_policy queue.arn
            attributes.merge! 'Policy' => policy
          end

          queue.set_attributes attributes
        end

        def delete
          @logger.info deleting_queue: @name

          queue_url = @sqs.get_queue_url(queue_name: @name)[:queue_url]
          @sqs.delete_queue(queue_url: queue_url)
        rescue ::Aws::SQS::Errors::NonExistentQueue
        end

        private

        def arn_array_policy_string arns, indent
          arns.sort.map { |arn| %(#{indent}"#{arn}") }.join(",\n")
        end

        def queue_policy queue.arn
          topic_arns = topics.map { |topic| @arns.sns_topic_arn topic }

          <<-EOS
{
  "Version": "2008-10-17",
  "Id": "#{queue.arn}/envoy-generated-policy",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "SQS:SendMessage",
      "Resource": "#{queue.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": [
#{arn_array_policy_string topic_arns, '            '}
          ]
        }
      }
    }
  ]
}
EOS
        end

        def redrive_policy dead_letter_queue, max_receive_count
          arn = @arns.sqs_queue.arn EnvironmentalName.new(dead_letter_queue).to_s
          %({"maxReceiveCount":"#{max_receive_count}", "deadLetterTargetArn":"#{arn}"})
        end

        def topics
          Shoryuken.worker_registry.topics(@name)
        end
      end
    end
  end
end
