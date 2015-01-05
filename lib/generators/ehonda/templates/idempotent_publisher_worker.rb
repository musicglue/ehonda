class IdempotentPublisherWorker
  include Celluloid
  include Ehonda::ActiveRecord

  def initialize autostart: false
    async.start if autostart
  end

  def start
    Shoryuken.logger.info log_data.merge(state: :starting)
    schedule_next_instance
    wait :stopping
  end

  private

  def log_data
    @log_data ||= { component: 'idempotent_publisher' }
  end

  def publisher
    @publisher ||= begin
      require 'ehonda/idempotent_publisher'
      Ehonda::IdempotentPublisher.new
    end
  end

  def schedule_next_instance
    after(@sleep ? 1 : 0) do
      @sleep = false

      with_connection do
        @message_count = publisher.publish.count
      end

      if @message_count > 0
        Shoryuken.logger.debug(log_data.merge(
          state: 'published',
          count: @message_count))
      else
        @sleep = true
      end

      schedule_next_instance
    end
  end
end
