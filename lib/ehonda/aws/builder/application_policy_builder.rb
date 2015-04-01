module Ehonda
  module Aws
    class Builder
      class ApplicationPolicyBuilder
        def initialize logger
          @logger = logger
          @arns = Arns.new
        end

        def build
          if Rails.env.development?
            file = Tempfile.create ['aws-application-policy', '.json']
            file.write application_policy
            @logger.info application_policy_written_to: file.path
          else
            group_policy = ::Aws::IAM::GroupPolicy.new(
              Ehonda.configuration.iam_group_name,
              Ehonda.configuration.iam_policy_name)

            @logger.info writing_policy: Ehonda.configuration.iam_policy_name, iam_group: Ehonda.configuration.iam_group_name

            group_policy.put policy_document: application_policy
          end
        end

        private

        def application_policy
          @application_policy ||= begin
            published_topic_arns = Ehonda.configuration.published_topics.map { |topic| @arns.sns_topic_arn topic }
            subscribed_topic_arns = Shoryuken.worker_registry.topics.map { |topic| @arns.sns_topic_arn topic }
            queue_arns = Shoryuken.worker_registry.queues.map { |queue| @arns.sqs_queue_arn queue }

            <<-EOS
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sns:Subscribe"
      ],
      "Resource": [
#{arn_array_policy_string subscribed_topic_arns, '        '}
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "sns:Publish"
      ],
      "Resource": [
#{arn_array_policy_string (published_topic_arns + subscribed_topic_arns), '        '}
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "sqs:ChangeMessageVisibility",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:GetQueueUrl",
        "sqs:ReceiveMessage"
      ],
      "Resource": [
#{arn_array_policy_string queue_arns, '        '}
      ]
    }
  ]
}
EOS
          end
        end

        def arn_array_policy_string arns, indent
          arns.uniq.sort.map { |arn| %(#{indent}"#{arn}") }.join(",\n")
        end
      end
    end
  end
end
