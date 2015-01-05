require_relative '../test_helper'
require 'stringio'
require 'ehonda/logging'

describe Ehonda::Logging do
  before do
    @output = StringIO.new

    Ehonda::Logging.default_log_device = @output
    Ehonda::Logging.logger = nil

    @logger = Ehonda::Logging.logger
  end

  it 'formats simple strings' do
    @logger.info 'some string'
    @output.string.must_match /severity="info" message="some string"/
  end

  it 'formats hashes' do
    @logger.warn foo: 1, bar: true, zoo: :wat?
    @output.string.must_match /severity="warn" foo="1" bar="true" zoo="wat\?"/
  end

  it 'formats hashes containing errors' do
    begin
      fail 'whoops'
    rescue => e
      @logger.error foo: 1, error: e
      @output.string.must_match /severity="error" foo="1" error="whoops" backtrace=".+"/
    end
  end
end
