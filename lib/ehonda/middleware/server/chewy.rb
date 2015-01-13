module Ehonda
  module Middleware
    module Server
      class Chewy
        def call(_worker, _queue, _sqs_msg, _body)
          ::Chewy.strategy(:atomic) do
            yield
          end
        end
      end
    end
  end
end
