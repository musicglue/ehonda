module Ehonda
  module Aws
    class EnvironmentalName
      def initialize(name)
        @name = [name.to_s.dasherize]
        @name << Rails.env if defined?(::Rails)
        @name = @name.join('-')
      end

      def to_s
        @name
      end
    end
  end
end
