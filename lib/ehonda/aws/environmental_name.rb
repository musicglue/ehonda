module Ehonda
  module Aws
    class EnvironmentalName
      def initialize(name)
        @name = [name.to_s.dasherize, Rails.env].join('-')
      end

      def to_s
        @name
      end
    end
  end
end
