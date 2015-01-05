module Ehonda
  class Configuration
    module Validatable
      def errors
        @errors ||= []
      end

      def valid?
        @errors = []
        validate
        @errors.empty?
      end
    end
  end
end
