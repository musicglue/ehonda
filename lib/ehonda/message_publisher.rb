module Ehonda
  class MessagePublisher
    def initialize
      config = Envoy.config
      config.validate!

      @sns = Ehonda.sns_client
      @arns = Ehonda::Aws::Arns.new
    end

    def publish message
      message = message.to_h if message.is_a?(Ehonda::TypedMessage)
      message = sanitizer.sanitize message

      message_type = message['header']['type'].underscore
      topic = Ehonda::Aws::EnvironmentalName.new(message_type).to_s
      topic_arn = @arns.sns_topic_arn topic

      @sns.publish topic_arn: topic_arn, message: message.to_json
    end

    private

    def sanitizer
      require 'ehonda/message_sanitizer'
      @sanitizer ||= MessageSanitizer.new
    end
  end
end
