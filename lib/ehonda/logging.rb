require 'logger'
require 'active_support/tagged_logging'

module Ehonda
  module Logging
    class Formatter
      include ActiveSupport::TaggedLogging::Formatter

      SEVERITY_TO_COLOR_MAP = {
        'DEBUG' => '0;37',
        'INFO' => '32',
        'WARN' => '33',
        'ERROR' => '31',
        'FATAL' => '31',
        'UNKNOWN' => '37'
      }

      DARK_COLOUR = "\e[90m"
      DEFAULT_COLOUR = "\033[0m"

      def call severity, time, _program_name, message
        data_hash = message.is_a?(Hash) ? message : { message: message }
        error_hash = {}

        %i(timestamp pid thread severity).each { |key| data_hash.delete key }

        if (error_object = data_hash.delete(:error))
          error_hash[:error] = error_object.to_s
          error_hash[:backtrace] = format_backtrace(error_object.backtrace) if error_object.backtrace
        end

        timestamp = write_kv('timestamp', time.utc.iso8601) if defined?(Rails) && Rails.env.development?

        severity_colour = "\033[#{SEVERITY_TO_COLOR_MAP[severity]}m"
        severity = format('%-5s', severity).downcase
        severity = %(#{severity_colour}#{severity})

        data = format_hash data_hash
        error = format_hash error_hash

        text = [timestamp]
        text << write_kv('pid', pid)
        text << write_kv('thread', thread)
        text << write_kv('severity', severity)
        text << data
        text << error

        "#{text.join(' ').strip}\n"
      end

      private

      def write_kv key, value
        %(#{DARK_COLOUR}#{key}="#{DEFAULT_COLOUR}#{value}#{DARK_COLOUR}"#{DEFAULT_COLOUR})
      end

      def escape string
        string.gsub(/"/, '"').gsub("\n", ' ')
      end

      def format_backtrace backtrace
        backtrace.map { |line| %("#{line}") }.join(', ')
      end

      def format_hash hash
        hash.map do |k, v|
          v = escape v.to_s
          write_kv k, v
        end.join ' '
      end

      def pid
        Process.pid
      end

      def thread
        Thread.current.object_id.to_s 36
      end
    end

    class << self
      attr_accessor :default_log_device
      attr_writer :logger

      def logger
        @logger ||= begin
          Logger.new(default_log_device || STDOUT).tap do |l|
            l.level = Logger::INFO
            l.formatter = Formatter.new
          end
        end
      end
    end
  end
end
