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
        Ehonda.configuration.require_workers
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
      index = 0
      ignorable = %w(
        transaction-account-allocation-required)

      File.open(Nenv.output, 'w+') do |file|
        DeadLetter.find_each do |message|
          unless ignorable.include? message.message['header']['type']
            file.write message.message.to_json
            file.write "\n"

            puts "#{index} message(s) written" if (index > 0) && (index % 1000 == 0)
            index += 1
          end
        end
      end
    end
  end

  namespace :processed_messages do
    desc "Publishes a list of messages JSON encoded in a file. Pass INPUT='/path/to/messages.json'."
    task :publish_all_from_file => :environment do
      require 'ehonda/message_publisher'

      publisher = Ehonda::MessagePublisher.new
      index = 0
      ignorable = %w(
        accounts-export-requested
        transaction-account-allocation-required
        transactions-export-requested)

      File.open(Nenv.input, 'r') do |file|
        loop do
          json = file.gets
          break if json.nil?

          hash = ActiveSupport::JSON.decode json

          unless ignorable.include? hash['header']['type']
            publisher.publish hash
            puts "#{index} message(s) published" if (index > 0) && (index % 1000 == 0)
            index += 1
          end
        end
      end
    end

    desc "JSON serializes all processed messages into a file. Pass OUTPUT='/path/to/messages.json'."
    task :write_all_to_file => :environment do
      File.open(Nenv.output, 'w+') do |file|
        ProcessedMessage.find_each.with_index do |message, index|
          file.write message.message.to_json
          file.write "\n"

          puts "#{index} message(s) written" if (index > 0) && (index % 1000 == 0)
        end
      end
    end
  end
end
