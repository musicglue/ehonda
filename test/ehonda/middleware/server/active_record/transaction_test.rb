require_relative '../../../../test_helper'
require 'ehonda/middleware/server/active_record/transaction'

middleware_class = Ehonda::Middleware::Server::ActiveRecord::Transaction
retrier_class = Ehonda::Middleware::Server::ActiveRecord::Retrier

describe middleware_class do
  let(:error) { nil }
  let(:worker) { Object.new }

  before do
    ::ActiveRecord::Base.expects(:transaction).at_least_once.with do |*args|
      @transaction_args = args
      true
    end.yields

    begin
      middleware_class.new(options).call(worker, nil, nil, nil) do
        fail error if error
        @called = true
      end
    rescue => e
      @error_raised = e
    end
  end

  describe 'active record transaction options' do
    describe "options are passed that are accepted by ActiveRecord's transaction method" do
      let(:options) { { requires_new: true, joinable: true, isolation: :repeatable_read } }

      it 'passes the accepted options' do
        @transaction_args.count.must_equal 1
        @transaction_args.first.must_equal options
      end

      it 'invokes the block supplied to the middleware' do
        @called.must_equal true
      end
    end

    describe "options are passed that are not accepted by ActiveRecord's transaction method" do
      let(:options) { { foo: 1, bar: 2 } }

      it 'does not pass the unaccepted options' do
        @transaction_args.count.must_equal 1
        @transaction_args.first.must_equal Hash.new
      end

      it 'invokes the block supplied to the middleware' do
        @called.must_equal true
      end
    end
  end

  describe 'retryable errors' do
    let(:worker) do
      Class.new do
        def log_retry(error)
          @log_retry_called = true
        end

        attr_reader :log_retry_called
      end.new
    end

    describe 'a retry callback method is named' do
      let(:options) { { on_retriable_error: :log_retry } }

      it 'invokes the block supplied to the middleware' do
        @called.must_equal true
      end

      describe 'the block supplied to the middleware raises an error' do
        describe 'the error is a record not unique error' do
          let(:error) { ::ActiveRecord::RecordNotUnique.new }

          it 'calls the callback' do
            worker.log_retry_called.must_equal true
          end
        end

        describe 'the error refers to a deadlock' do
          let(:error) do
            ActiveRecord::StatementInvalid.new 'PG::TRDeadlockDetected: '\
              'ERROR: deadlock detected '\
              'DETAIL: Process 1105 waits for ShareLock on transaction 1197700; blocked b.... '\
              'Process 1043 waits for ShareLock on transaction 1197560; blocked by process 1105. '\
              'HINT: See server log for query details.'
          end

          it 'calls the callback' do
            worker.log_retry_called.must_equal true
          end
        end

        describe 'the error refers to a serializable isolation level error' do
          let(:error) do
            ActiveRecord::StatementInvalid.new 'PG::TRSerializationFailure: '\
              'ERROR: could not serialize access due to read/write dependencies among transactions '\
              'DETAIL: Reason code: Canceled on identification as a pivot, during conflict in checking. '\
              'HINT: The transaction might succeed if retried.'
          end

          it 'calls the callback' do
            worker.log_retry_called.must_equal true
          end
        end

        describe 'the error refers to something else' do
          let(:error) { ActiveRecord::StatementInvalid.new 'TRFoobar' }

          it 'does not call the callback' do
            (!!worker.log_retry_called).must_equal false
          end
        end

        describe 'the error is not retriable' do
          let(:error) { StandardError.new }

          it 'does not call the callback' do
            (!!worker.log_retry_called).must_equal false
          end
        end
      end
    end
  end
end

