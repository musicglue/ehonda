module EHonda
  module Middleware
    module Server
      class ActiveRecordConnectionPool
        def call(*args)
          ::ActiveRecord::Base.connection_pool.with_connection do
            yield
          end
        end
      end
    end
  end
end
