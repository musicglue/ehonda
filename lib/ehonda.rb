require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/json'
require 'aws-sdk-resources'
require 'shoryuken'
require 'ehonda/version'
require 'ehonda/logging'
require 'ehonda/configuration'
require 'ehonda/railtie' if defined? Rails

module Ehonda
  class << self
    def configure
      @config ||= Configuration.new
      yield @config if block_given?
      @config.validate! unless (ENV['RAILS_ENV'] || ENV['RACK_ENV']) == 'test'
    end

    def configuration
      fail 'You must call Ehonda.configure before you can access any config.' unless @config
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
