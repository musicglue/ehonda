module Ehonda
  class Configuration
    class RedrivePolicyConfiguration
      include Validatable

      def initialize owner
        @owner = owner
        @enabled = true
        @max_receive_count = 10
      end

      attr_accessor :enabled,
                    :max_receive_count,
                    :dead_letter_queue

      def validate
        unless (1..1000).include? max_receive_count
          errors << "#{@owner.name}.redrive_policy.max_receive_count must be in the range 1..1000"
        end

        return unless enabled && dead_letter_queue.blank?

        errors << "#{@owner.name}.redrive_policy.dead_letter_queue is required"
      end

      def copy_onto redrive_policy
        redrive_policy.enabled = enabled
        redrive_policy.max_receive_count = max_receive_count
        redrive_policy.dead_letter_queue = dead_letter_queue
      end
    end
  end
end
