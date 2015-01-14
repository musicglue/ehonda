require_relative 'configuration/validatable'
require_relative 'configuration/queue_configuration'
require_relative 'configuration/redrive_policy_configuration'

module Ehonda
  class Configuration
    include Validatable

    def initialize
      @queues = {}
      @queue_defaults = QueueConfiguration.new 'queue_defaults'
      @sns_protocol = @sqs_protocol = 'sqs'
    end

    attr_reader :queue_defaults, :sns_endpoint, :sns_protocol, :sqs_endpoint, :sqs_protocol

    def add_queue name
      environmental_name = Aws::EnvironmentalName.new(name).to_s
      fail "A queue called #{name} already exists." if @queues.key? environmental_name

      queue = QueueConfiguration.new name
      @queue_defaults.copy_onto queue
      yield queue if block_given?
      @queues[environmental_name] = queue
    end

    def aws_options
      @aws_options ||= shoryuken_config[:aws].slice :access_key_id, :region, :secret_access_key
    end

    def aws_account_id
      shoryuken_config[:aws][:account_id]
    end

    def aws_region
      aws_options[:region]
    end

    def enable_cmb_mode
      @sns_protocol = @sqs_protocol = 'cqs'
      @sns_endpoint = shoryuken_config[:aws][:sns_endpoint]
      @sqs_endpoint = shoryuken_config[:aws][:sqs_endpoint]
    end

    def queues
      @queues.values
    end

    def get_queue environmental_name
      @queues[environmental_name]
    end

    def require_workers
      Dir[Rails.root + '**' + 'app' + 'workers' + '*.rb'].each do |path|
        require path
      end
    end

    def shoryuken_config
      @shoryuken_config ||= begin
        YAML.load(
          ERB.new(
            IO.read(
              Rails.root + 'config' + 'shoryuken.yml')
            ).result
          ).with_indifferent_access
      end
    end

    def sns_options
      aws_client_options :sns_endpoint
    end

    def sqs_options
      aws_client_options :sqs_endpoint
    end

    def use_ehonda_logging
      require 'ehonda/logging'

      Ehonda::Logging.logger = Logger.new(STDOUT).tap do |l|
        l.level = Shoryuken::Logging.logger.level
        l.formatter = Ehonda::Logging::Formatter.new
      end

      Shoryuken::Logging.logger = Ehonda::Logging.logger
    end

    def use_typed_message_registry dead_letter_queue_name
      require 'ehonda/worker_registries/typed_message_registry'
      Shoryuken.worker_registry = Ehonda::WorkerRegistries::TypedMessageRegistry.new dead_letter_queue_name
    end

    def validate
      [queue_defaults, queues].flatten.compact.each do |section|
        section.valid?
        errors.push *(section.errors)
      end
    end

    def validate!
      return if valid?

      fail %(Invalid configuration: \n\n#{errors.join("\n")}\n\n)
    end

    private

    def aws_client_options endpoint_key
      options = aws_options
      endpoint = shoryuken_config[:aws][endpoint_key]
      options = options.merge(endpoint: endpoint) unless endpoint.blank?
      options
    end
  end
end
