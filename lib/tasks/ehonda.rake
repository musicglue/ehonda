namespace :ehonda do
  namespace :aws do
    namespace :build do
      desc 'Builds policies, topics and queues'
      task all: %i(environment topics queues subscriptions policies) do
      end

      desc 'Builds the application policies'
      task policies: :environment do
        builder.build_policies
      end

      desc 'Builds the queues'
      task queues: :environment do
        builder.build_queues
      end

      desc 'Builds the subscriptions'
      task subscriptions: :environment do
        builder.build_subscriptions
      end

      desc 'Builds the topics'
      task topics: :environment do
        builder.build_topics
      end

      private

      def builder
        require 'ehonda/aws/builder'
        Ehonda::Aws::Builder.new
      end
    end

    namespace :destroy do
      desc 'Deletes all topics and queues'
      task all: :environment do
        fail 'This task is only available in development.' unless Rails.env.development?
        builder.delete_all
      end
    end
  end

  namespace :dead_letters do
    desc 'Retries all dead letters (or pass SQS_ID or MESSAGE_ID to select a specific message).'
    task retry: :environment do
      require 'ehonda/dead_letters/retrier'
      scope = DeadLetter.retriable sqs_id: ENV['SQS_ID'], message_id: ENV['MESSAGE_ID']
      Ehonda::DeadLetters::Retrier.new.retry scope
    end

    desc "JSON serializes all processed messages into a file. Pass OUTPUT='/path/to/messages.json'."
    task :write_all_to_file => :environment do
      require 'ehonda/message_file_serializer'
      Ehonda::MessageFileSerializer.new(Nenv.output).write DeadLetter.all
    end
  end

  namespace :messages do
    desc "Publishes a list of messages JSON encoded in a file. Pass INPUT='/path/to/messages.json'."
    task :publish_all_from_file => :environment do
      require 'ehonda/message_publisher'
      require 'ehonda/count_logger'

      path = Nenv.input
      publisher = Ehonda::MessagePublisher.new
      counter = Ehonda::CountLogger.new { |index| "#{index} message(s) published" }

      ignorable = %w(
        accounts-export-requested
        transaction-account-allocation-required
        transactions-export-requested)

      File.open(path, 'r') do |file|
        loop do
          json = file.gets
          break if json.nil?

          message = Ehonda::TypedMessage.new(json)

          unless ignorable.include? message.type
            publisher.publish message.to_h
            counter.count
          end
        end
      end

      Shoryuken.logger.info "Messages published from #{path}."
    end
  end

  namespace :processed_messages do
    desc "JSON serializes all processed messages into a file. Pass OUTPUT='/path/to/messages.json'."
    task :write_all_to_file => :environment do
      require 'ehonda/message_file_serializer'
      Ehonda::MessageFileSerializer.new(Nenv.output).write ProcessedMessage.all
    end
  end
end
