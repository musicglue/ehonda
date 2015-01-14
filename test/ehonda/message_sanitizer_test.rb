require_relative '../test_helper'
require 'ehonda/message_sanitizer'

describe Ehonda::MessageSanitizer do
  before do
    @sanitizer = Ehonda::MessageSanitizer.new
    @valid_message = {
      header: {
        id: SecureRandom.uuid,
        type: 'some-sort-of-message',
        version: 1
      },
      'body' => {
        blah: SecureRandom.uuid
      }
    }
  end

  it 'removes unacceptable hash keys' do
    message = @valid_message.merge('foo' => 1, bar: 2)
    message = @sanitizer.sanitize message
    message.keys.count.must_equal 2
    message.keys.must_include 'header'
    message.keys.must_include 'body'
  end

  it 'normalizes the use of a headers key' do
    message = @valid_message
    message[:headers] = message.delete :header
    message = @sanitizer.sanitize message
    message.keys.must_include 'header'
    message.keys.wont_include 'headers'
    message['header']['type'].must_equal 'some-sort-of-message'
  end

  it 'fails on hashes which do not include a header' do
    message = @valid_message
    message.delete :header
    ->{ @sanitizer.sanitize message }.must_raise Ehonda::MessageSanitizer::InvalidMessageError
  end

  it 'fails on hashes which do not include a body' do
    message = @valid_message
    message.delete 'body'
    ->{ @sanitizer.sanitize message }.must_raise Ehonda::MessageSanitizer::InvalidMessageError
  end

  it 'returns a hash with indifferent access' do
    message = @sanitizer.sanitize @valid_message
    message['header'].must_equal message[:header]
    message['body'].must_equal message[:body]
  end
end
