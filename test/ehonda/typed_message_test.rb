require_relative '../test_helper'
require 'active_attr'
require 'ehonda/typed_message'

describe Ehonda::TypedMessage do
  before do
    @typed_message = Ehonda::TypedMessage
    @valid_message = {
      headers: {
        id: SecureRandom.uuid,
        type: 'some-type',
        version: 1
      },
      body: {
        some_key: 'some value'
      }}

    @valid_message_json = ActiveSupport::JSON.encode @valid_message
  end

  it 'can be built from a valid message hash' do
    message = @typed_message.new @valid_message

    message.to_h['body']['some_key'].must_equal 'some value'
  end

  it 'can be built from valid message json' do
    message = @typed_message.new @valid_message_json

    message.to_h['body']['some_key'].must_equal 'some value'
  end

  it 'can be built from valid non-raw format message json' do
    non_raw_hash = { 'Message' => @valid_message_json }
    message = @typed_message.new non_raw_hash

    message.to_h['body']['some_key'].must_equal 'some value'
  end

  it 'fails when building from invalid json' do
    invalid_json = ActiveSupport::JSON.encode(blah: 123)

    ->{ @typed_message.new(invalid_json).to_h }.must_raise Ehonda::MessageSanitizer::InvalidMessageError
  end

  it 'can be built from an existing typed message' do
    message = @typed_message.new @valid_message
    message2 = @typed_message.new message
    message2.to_h['body']['some_key'].must_equal 'some value'
  end

  it 'can be built from an active attr model' do
    MyMessage = Class.new do
      include ActiveAttr::Model

      attribute :foo
    end

    message = @typed_message.new MyMessage.new(foo: 121)
    message.to_h['body']['foo'].must_equal 121
  end

  it 'can be built from an Shoryuken::Message' do
    if defined? ::Shoryuken::Message
      shoryuken_message = Shoryuken::Message.new(
        Object.new,
        'http://example.org/queue1',
        { body: @valid_message_json })
      message = @typed_message.new shoryuken_message
      message.to_h['body']['some_key'].must_equal 'some value'
    end
  end

  it 'can be built from an Shoryuken::Message' do
    if defined? ::Aws::SQS::Message
      sqs_message = Aws::SQS::Message.new(
        queue_url: 'http://example.org/queue1',
        client: Object.new,
        receipt_handle: SecureRandom.uuid,
        data: { body: @valid_message_json })
      message = @typed_message.new sqs_message
      message.to_h['body']['some_key'].must_equal 'some value'
    end
  end
end
