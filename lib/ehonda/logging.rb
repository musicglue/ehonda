require 'logger'

module Ehonda
  module Logging
    class Formatter < Logger::Formatter
      def call severity, time, _program_name, message
        data_hash = message.is_a?(Hash) ? message : { message: message }
        error_hash = {}

        %i(timestamp pid thread severity).each { |key| data_hash.delete key }

        if (error_object = data_hash.delete(:error))
          error_hash[:error] = error_object.to_s
          error_hash[:backtrace] = format_backtrace(error_object.backtrace) if error_object.backtrace
        end

        timestamp = %Q{timestamp="#{time.utc.iso8601}"} if Rails.env.development?
        severity = severity.downcase
        data = format_hash data_hash
        error = format_hash error_hash

        text = %(#{timestamp} pid="#{pid}" thread="#{thread}" severity="#{severity}" #{data} #{error}).strip

        "#{text}\n"
      end

      private

      def escape string
        string.gsub(/"/, '"').gsub("\n", ' ')
      end

      def format_backtrace backtrace
        backtrace.map { |line| %("#{line}") }.join(', ')
      end

      def format_hash hash
        hash.map do |k, v|
          v = escape v.to_s
          %(#{k}="#{v}")
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
