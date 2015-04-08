# Load any middlewares you want to use:
#
# require 'ehonda/middleware/server/airbrake'
# require 'ehonda/middleware/server/active_record/connection_pool'

# Configure your environment:
#
# Ehonda.configure do |config|
#   config.use_ehonda_logging
#   config.use_typed_message_registry 'your_dead_letter_queue_name'
#   config.enable_cmb_mode if Rails.env.development?
#
#   config.queue_defaults.delay_seconds = 0
#   config.queue_defaults.message_retention_period = 1_209_600
#   config.queue_defaults.visibility_timeout = 30

#   config.add_queue('your_dead_letter_queue_name') do |queue|
#     queue.visibility_timeout = 60
#   end

#   config.add_queue('your_queue_name') do |queue|
#     queue.delay_seconds = 10
#     queue.redrive_policy.dead_letter_queue = 'your_dead_letter_queue_name'
#     queue.redrive_policy.enabled = true
#     queue.redrive_policy.max_receive_count = 5
#   end
#
#   config.add_queue 'another_queue_name'
#
#   config.published_messages = %w(
#     SomethingMessage
#     SomethingElseMessage
#   )
# end
#
# Force workers to register themselves with Shoryuken under Rails.env.development,
# because otherwise Rails doesn't know about them until their constants are autoloaded.
# This is necessary for the rake tasks to work correctly.
#
# if Rails.env.development?
#   FooWorker
#   BarWorker
# end

Shoryuken.on_start do
  Celluloid.logger = Shoryuken.logger
end
