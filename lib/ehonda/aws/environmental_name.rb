module Ehonda
  module Aws
    class EnvironmentalName
      def initialize(name)
        @name = [name.to_s.dasherize]

        if !ENV['AWS_ENV'].blank?
          @name << ENV['AWS_ENV']
        elsif defined?(::Rails)
          @name << Rails.env
        end

        @name = @name.join('-')
      end

      def to_s
        @name
      end
    end
  end
end
