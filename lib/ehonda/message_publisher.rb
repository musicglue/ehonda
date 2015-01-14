module Ehonda
  class MessagePublisher
    InvalidMessageError = Class.new StandardError

    def initialize sns: Ehonda.sns_client
      require 'ehonda/aws/arns'
      require 'ehonda/aws/environmental_name'
      require 'ehonda/message_sanitizer'
      require 'ehonda/typed_message'

      @sns = sns
      @arns = Ehonda::Aws::Arns.new
      @sanitizer = MessageSanitizer.new
    end

    def publish message, headers = {}
      message = Ehonda::TypedMessage.new(message).to_h
      message['header'].merge! headers
      message = @sanitizer.sanitize message

      @sns.publish topic_arn: topic_arn(message), message: message.to_json
    end

    private

    def topic_arn message
      message_type = message['header']['type'].underscore
      topic = Ehonda::Aws::EnvironmentalName.new(message_type).to_s
      @arns.sns_topic_arn topic
    end
  end
end
