require 'test_helper'

describe Barrister::RedisTransport do

  before do
    @trans = Barrister::RedisTransport.new('test', {})
  end

  describe '.timeout' do

    it 'is set by default' do
      @trans.timeout.must_equal 30
    end

    it 'can be set when initializing' do
      Barrister::RedisTransport.new('test', timeout: 60).timeout.must_equal 60
    end

    it 'is passed to brpop' do
      @trans.client = MiniTest::Mock.new
      @trans.client.expect :lpush, true, [String, String]
      @trans.client.expect :brpop, {}, [String, 60]

      @trans.timeout = 60
      @trans.request('message')
      @trans.client.verify
    end

  end

  describe '.request' do
    it 'deals withs timeouts' do
      @trans.client = @trans.client.stub(:brpop, nil) do
        @trans.request('message')
      end
    end
  end

end
