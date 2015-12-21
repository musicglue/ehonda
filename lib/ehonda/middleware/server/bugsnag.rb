module Ehonda
  module Middleware
    module Server
      class Bugsnag
        def call(worker, queue, sqs_msg, body)
          yield
        rescue => e
          errors = only_dead_letter_errors worker
          retries_exhausted = false

          if errors.any?
            current_retry = retry_number(sqs_msg)
            max = max_retries(queue)

            retries_exhausted = (current_retry || max) >= max
          end

          notifiable = errors.empty? || (error_is_class(e, errors) && retries_exhausted)

          if notifiable
            parameters = {}

            begin
              message = TypedMessage.new sqs_msg
              parameters.store :message, message.headers
            rescue
              parameters.store :unknown_message_format, body
            end

            notify e, parameters: parameters
          end

          raise e
        end

        def error_is_class error, classes
          classes.any? { |klass| error.is_a? klass }
        end

        def only_dead_letter_errors worker
          opts = worker.class.get_shoryuken_options['bugsnag'] || {}
          [opts['only_on_dead_letter']].flatten.compact.uniq
        end

        def max_retries queue
          sqs = Shoryuken::Client.sqs
          url = sqs.get_queue_url(queue_name: queue).queue_url

          json = sqs.get_queue_attributes(
            attribute_names: %w(RedrivePolicy),
            queue_url: url).attributes['RedrivePolicy']

          return 0 if json.blank?

          begin
            ActiveSupport::JSON.decode(json)['maxReceiveCount']
          rescue
            0
          end
        end

        def notify error, parameters
          ::Bugsnag.notify error, parameters: parameters
        end

        def retry_number sqs_msg
          sqs_msg.attributes['ApproximateReceiveCount']
        end
      end
    end
  end
end

__END__

  shoryuken_options(
    bugsnag: {
      only_dead_letter_errors: UpdatePlatformFeeContractFromUserAppService::SubjectNotFoundError },

    subscriptions: {
      financials_jobs: 'platform_fee_contract_updated_by_user_app' })
