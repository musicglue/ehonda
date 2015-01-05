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
      scope = DeadLetter.retriable sqs_id: ENV['SQS_ID'], message_id: ENV['MESSAGE_ID']
      Ehonda::DeadLetterRetrier.new.retry scope
    end
  end
end
