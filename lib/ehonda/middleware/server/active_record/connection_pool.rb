module Ehonda
  module Middleware
    module Server
      module ActiveRecord
        class ConnectionPool
          def call(*_args)
            ::ActiveRecord::Base.connection_pool.with_connection do
              yield
            end
          end
        end
      end
    end
  end
end
