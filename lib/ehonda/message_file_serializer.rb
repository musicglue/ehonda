require_relative 'count_logger'

module Ehonda
  class MessageFileSerializer
    def initialize path
      @path = path
    end

    def write scope
      counter = CountLogger.new { |index| "#{index} message(s) written" }

      File.open(@path, 'w+') do |file|
        method = scope.respond_to?(:find_each) ? :find_each : :each

        scope.send(method) do |message|
          file.write message.message.to_json
          file.write "\n"
          counter.count
        end
      end

      Shoryuken.logger.info "Messages written to #{@path}."
    end
  end
end
