require 'shoryuken'
require 'ehonda/version'
require 'ehonda/logging'
require 'ehonda/configuration'
require 'ehonda/railtie' if defined? Rails

module Ehonda
  class << self
    def configure
      @config ||= Configuration.new.tap do |config|
        yield config
        config.validate!
      end
    end

    def configuration
      fail 'You must call Ehonda.configure in an initializer.' unless @config
      @config
    end

    def sns_client
      ::Aws::SNS::Client.new configuration.sns_options
    end

    def sqs_client
      ::Aws::SQS::Client.new configuration.sqs_options
    end
  end
end
