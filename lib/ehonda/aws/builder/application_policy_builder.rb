module Ehonda
  module Aws
    class Builder
      class ApplicationPolicyBuilder
        def initialize logger
          @logger = logger
          @arns = Arns.new
        end

        def build
          file = Tempfile.create ['aws-application-policy', '.json']
          file.write application_policy
          @logger.info application_policy_written_to: file.path
        end

        private

        def application_policy
          topic_arns = Shoryuken.worker_registry.topics.map { |topic| @arns.sns_topic_arn topic }
          queue_arns = Shoryuken.worker_registry.queues.map { |queue| @arns.sqs_queue_arn queue }

          <<-EOS
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sns:CreateTopic",
        "sns:Publish",
        "sns:SetEndpointAttributes",
        "sns:Subscribe"
      ],
      "Resource": [
#{arn_array_policy_string topic_arns, '        '}
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "sns:SetSubscriptionAttributes"
      ],
      "Resource": [
        "#{@arns.sns_topic_arn '*'}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "sqs:ChangeMessageVisibility",
        "sqs:CreateQueue",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:GetQueueUrl",
        "sqs:ReceiveMessage",
        "sqs:SetQueueAttributes"
      ],
      "Resource": [
#{arn_array_policy_string queue_arns, '        '}
      ]
    }
  ]
}
EOS
        end

        def arn_array_policy_string arns, indent
          arns.sort.map { |arn| %(#{indent}"#{arn}") }.join(",\n")
        end
      end
    end
  end
end
