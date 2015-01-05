module ActiveRecord
  class Base
    class << self
      def forbid_implicit_checkout!
        Thread.current[:active_record_forbid_implicit_connections] = true
      end

      def implicit_checkout_forbidden?
        !!Thread.current[:active_record_forbid_implicit_connections]
      end

      def connection_with_forbid_implicit(*args, &block)
        if implicit_checkout_forbidden? && !connection_handler.retrieve_connection_pool(self).active_connection?
          message = 'Implicit ActiveRecord checkout attempted when Thread :force_explicit_connections set!'

          # I want to make SURE I see this error in test output, even though
          # in some cases my code is swallowing the exception.
          $stderr.puts(message) if Rails.env.test?

          fail ImplicitConnectionForbiddenError, message
        end

        connection_without_forbid_implicit(*args, &block)
      end

      alias_method_chain :connection, :forbid_implicit
    end
  end

  # We're refusing to give a connection when asked for. Same outcome
  # as if the pool timed out on checkout, so let's subclass the exception
  # used for that.
  ImplicitConnectionForbiddenError = Class.new(::ActiveRecord::ConnectionTimeoutError)
end
