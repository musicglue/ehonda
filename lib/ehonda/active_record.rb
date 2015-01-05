module Ehonda
  module ActiveRecord
    extend ActiveSupport::Concern

    def with_connection
      ::ActiveRecord::Base.connection_pool.with_connection do
        yield
      end
    end

    def with_transaction opts
      ::ActiveRecord::Base.transaction(opts) do
        yield
      end
    end
  end
end
