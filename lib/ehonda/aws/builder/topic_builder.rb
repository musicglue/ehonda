module Ehonda
  module Aws
    class Builder
      class TopicBuilder
        def initialize logger, name
          @logger = logger
          @name = EnvironmentalName.new(name).to_s
          @sns = Ehonda.sns_client
          @arns = Arns.new
        end

        def build
          @logger.info building_topic: @name

          @sns.create_topic name: @name
        end

        def delete
          @logger.info deleting_topic: @name

          @sns.delete_topic topic_arn: @arns.sns_topic_arn(@name)
        rescue ::Aws::SNS::Errors::NotFound
        end
      end
    end
  end
end
