module Ehonda
  module Aws
    class Arns
      def sns_arn
        if Ehonda.configuration.sns_protocol == 'cqs'
          "arn:cmb:cns:ccp:#{Ehonda.configuration.aws_account_id}"
        else
          "arn:aws:sns:#{Ehonda.configuration.aws_region}:#{Ehonda.configuration.aws_account_id}"
        end
      end

      def sns_topic_arn topic
        "#{sns_arn}:#{topic}"
      end

      def sqs_arn
        if Ehonda.configuration.sqs_protocol == 'cqs'
          "arn:cmb:cqs:ccp:#{Ehonda.configuration.aws_account_id}"
        else
          "arn:aws:sqs:#{Ehonda.configuration.aws_region}:#{Ehonda.configuration.aws_account_id}"
        end
      end

      def sqs_queue_arn queue
        "#{sqs_arn}:#{queue}"
      end
    end
  end
end
