module Ehonda
  class MessagePublisher
    InvalidMessageError = Class.new StandardError

    def initialize
      require 'ehonda/aws/arns'
      require 'ehonda/aws/environmental_name'
      require 'ehonda/message_sanitizer'

      @sns = Ehonda.sns_client
      @arns = Ehonda::Aws::Arns.new
      @sanitizer = MessageSanitizer.new
    end

    def publish message, headers = {}
      message = if message.is_a?(ActiveAttr::Model)
        convert_active_attr_model_to_hash message, headers
      elsif message.is_a?(Ehonda::TypedMessage)
        message.to_h
      end

      fail InvalidMessageError, "MessagePublisher expects an ActiveAttr::Model, "\
                                "an Ehonda::TypedMessage or a hash, but got "\
                                "a #{message.class}." unless message.is_a?(Hash)

      message = @sanitizer.sanitize message

      @sns.publish topic_arn: topic_arn(message), message: message.to_json
    end

    private

    def convert_active_attr_model_to_hash model, headers
      topic_name = model.class.to_s.underscore.dasherize.sub(/-message$/, '')
      headers.merge!(type: topic_name).reverse_merge!(id: SecureRandom.uuid, version: 1)

      { header: headers, body: model.attributes }
    end

    def topic_arn message
      message_type = message['header']['type'].underscore
      topic = Ehonda::Aws::EnvironmentalName.new(message_type).to_s
      @arns.sns_topic_arn topic
    end
  end
end
