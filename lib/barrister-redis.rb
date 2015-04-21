require "barrister-redis/version"
require 'barrister'
require 'redis'

module Barrister

  class RedisTransport

    attr_accessor :client, :timeout

    def initialize(list_name, options={})
      options = {
        database_url: 'redis://localhost:6379'
      }.merge(options)

      @timeout = options[:timeout] || 30
      @list_name = list_name
      @client = ::Redis.connect url: options[:database_url]
    end

    def request(message)
      # reply-to tells the server where we'll be listening
      request = {
        'reply_to' => 'reply-' + SecureRandom.uuid,
        'message'  => message
      }

      # insert our request at the head of the list
      @client.lpush(@list_name, JSON.generate(request))

      # pop last element off our list in a blocking fashion
      channel, response = @client.brpop(request['reply_to'], timeout)

      return {"jsonrpc"=>"2.0", "result"=> []}  unless channel and response

      JSON.parse(response)['message']
    end

  end

  class RedisContainer

    def initialize(json_path, handlers, options={})
      options = {
        database_url: 'redis://localhost:6379',
        list_name: json_path.split('/')[-1].split('.')[0]
      }.merge(options)

      @list_name = options[:list_name]

      # establish connection to Redis
      @client = ::Redis.connect url: options[:database_url]

      # initialize service
      contract = Barrister::contract_from_file(json_path)
      @server  = Barrister::Server.new(contract)

      # in case we are passed a single handler
      handlers = handlers.kind_of?(Array) ? handlers : [handlers]

      # register each provided handler
      handlers.each do |handler|
        iface_name = handler.class.to_s.split('::').last
        @server.add_handler iface_name, handler
      end
    end

    def start
      while true
        # pop last element off our list in a blocking fashion
        channel, request = @client.brpop(@list_name)

        parsed = JSON.parse request

        # reverse the message we were sent
        response = {
          'message' => @server.handle(parsed['message'])
        }

        # 'respond' by inserting our reply at the head of a 'reply'-list
        @client.lpush(parsed['reply_to'], JSON.generate(response))
      end
    end

  end

end
