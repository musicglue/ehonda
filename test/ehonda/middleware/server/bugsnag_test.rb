require_relative '../../../test_helper'
require 'ehonda/middleware/server/bugsnag'

describe Ehonda::Middleware::Server::Bugsnag do
  ImportantError = Class.new StandardError

  class StubWorker
    def self.get_shoryuken_options
      @options
    end

    def self.set_shoryuken_options options
      @options = options
    end
  end

  before do
    StubWorker.set_shoryuken_options({})
    @middleware = Ehonda::Middleware::Server::Bugsnag.new

    @queue_name = 'test-queue-x'
    # @sqs = stub
    @worker = StubWorker.new

    @body = {
      'header' => {
        'id' => SecureRandom.uuid,
        'type' => 'something-happened'
      },
      'body' => {}
    }

    @original_header = @body['header'].dup
    @message = ::Aws::SQS::Types::Message.new(
      attributes: {},
      body: ActiveSupport::JSON.encode(@body))
  end

  def invoke
    @middleware.call(@worker, @queue_name, @message, @body) do
      raise @error if @error
    end
  end

  def do_not_expect_notification
    @middleware.expects(:notify).never
  end

  def expect_notification
    @middleware.expects(:notify).once.with do |error, opts|
      error.must_be_instance_of @error
      opts[:parameters][:message].must_equal @original_header
    end
  end

  describe 'the worker does not raise any errors' do
    it 'does not notify bugsnag' do
      do_not_expect_notification
      invoke
    end
  end

  describe 'the worker raises an error' do
    before do
      @error = ImportantError
    end

    describe 'and bugsnag should always be notified' do
      it 'notifies bugsnag' do
        expect_notification
        -> { invoke }.must_raise ImportantError
      end
    end

    describe 'and bugsnag should be notified only on the final attempt before dead-lettering' do
      before do
        StubWorker.set_shoryuken_options(
          'bugsnag' => {
            'only_on_dead_letter' => ImportantError })
      end

      describe "and the message does not describe it's retry number" do
        before do
          @middleware.stubs(:max_retries).returns 5
          @middleware.stubs(:retry_number).returns nil
        end

        it 'notifies bugsnag' do
          expect_notification
          -> { invoke }.must_raise ImportantError
        end
      end

      describe "and the message describes it's retry number" do
        describe 'and the queue has no redrive policy that lists max attempts' do
          before do
            @middleware.stubs(:max_retries).returns 0
            @middleware.stubs(:retry_number).returns 1
          end

          it 'notifies bugsnag' do
            expect_notification
            -> { invoke }.must_raise ImportantError
          end
        end

        describe 'and the queue has a redrive policy that lists max attempts' do
          describe 'and it is not the final attempt before dead-lettering' do
            before do
              @middleware.stubs(:max_retries).returns 5
              @middleware.stubs(:retry_number).returns 1
            end

            it 'does not notify bugsnag' do
              do_not_expect_notification
              -> { invoke }.must_raise ImportantError
            end
          end

          describe 'and it is the final attempt before dead-lettering' do
            before do
              @middleware.stubs(:max_retries).returns 5
              @middleware.stubs(:retry_number).returns 5
            end

            it 'notifies bugsnag' do
              expect_notification
              -> { invoke }.must_raise ImportantError
            end
          end
        end
      end
    end
  end
end

