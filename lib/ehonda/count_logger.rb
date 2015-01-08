module Ehonda
  class CountLogger
    def initialize &block
      @index = 0
      @block = block
    end

    def count
      if (@index > 0) && (@index % 1000 == 0)
        message = @block.call @index
        Shoryuken.logger.info message
      end

      @index += 1
    end
  end
end
