require_relative '../test_helper'
require 'ehonda/message_publisher'
require 'active_attr'

describe Ehonda::MessagePublisher do
  class SnsStub
    def publish(topic_arn:, message:)
      self.topic_arn = topic_arn
      self.message = ActiveSupport::JSON.decode message
    end

    attr_accessor :topic_arn, :message
  end

  before do
    @sns = SnsStub.new

    ehonda_config = mock
    ehonda_config.stubs(:sns_protocol).returns 'cqs'
    ehonda_config.stubs(:aws_account_id).returns 1234567890

    Ehonda.stubs(:configuration).returns ehonda_config

    @publisher = Ehonda::MessagePublisher.new sns: @sns

    @valid_message = {
      header: {
        id: SecureRandom.uuid,
        type: 'some-sort-of-message',
        version: 1
      },
      'body' => {
        blah: 'xyzxyz'
      }
    }
  end

  it 'can publish a TypedMessage' do
    message = Ehonda::TypedMessage.new @valid_message

    @publisher.publish message

    @sns.topic_arn.must_equal 'arn:cmb:cns:ccp:1234567890:some-sort-of-message'
    @sns.message['body']['blah'].must_equal 'xyzxyz'
  end

  it 'can publish a TypedMessage with extra headers' do
    message = Ehonda::TypedMessage.new @valid_message

    @publisher.publish message, version: 2, this: 'that'

    @sns.topic_arn.must_equal 'arn:cmb:cns:ccp:1234567890:some-sort-of-message'
    @sns.message['header']['this'].must_equal 'that'
    @sns.message['header']['version'].must_equal 2
    @sns.message['body']['blah'].must_equal 'xyzxyz'
  end

  it 'can publish a hash' do
    @publisher.publish @valid_message

    @sns.topic_arn.must_equal 'arn:cmb:cns:ccp:1234567890:some-sort-of-message'
    @sns.message['body']['blah'].must_equal 'xyzxyz'
  end

  it 'can publish a hash with extra headers' do
    @publisher.publish @valid_message, version: 2, this: 'that'

    @sns.topic_arn.must_equal 'arn:cmb:cns:ccp:1234567890:some-sort-of-message'
    @sns.message['header']['this'].must_equal 'that'
    @sns.message['header']['version'].must_equal 2
    @sns.message['body']['blah'].must_equal 'xyzxyz'
  end

  it 'can publish an arbitrary model as a typed message' do
    ThingHappenedMessage = Class.new do
      include ActiveAttr::Model

      attribute :foo
    end

    message = ThingHappenedMessage.new(foo: 'wat')
    @publisher.publish message

    @sns.topic_arn.must_equal 'arn:cmb:cns:ccp:1234567890:thing-happened'
    @sns.message['body']['foo'].must_equal 'wat'
  end
end
