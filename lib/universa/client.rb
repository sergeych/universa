require 'boss-protocol'
require 'open-uri'
require 'concurrent'

module Universa

  using Universa

  def retry_with_timeout(max_timeout = 15, max_times = 3, &block)
    attempt = 0
    Timeout::timeout(max_timeout, &block)
  rescue
    attempt += 1
    puts "timeout: retry (#$!): #{attempt}"
    retry if attempt < max_times
    raise
  end


  module Parallel

    class ParallelEnumerable < SimpleDelegator
      include Concurrent

      @@pool = CachedThreadPool.new

      def each_with_index &block
        latch = CountDownLatch.new(size)
        __getobj__.each_with_index {|x, index|
          @@pool << -> {
            begin
              block.call(x, index)
            rescue
              $!.print_stack_trace
            ensure
              latch.count_down
            end
          }
        }
        latch.wait
      end

      def each &block
        each_with_index {|x, i| block.call(x)}
      end


      def map &block
        result = size.times.map {nil}
        each_with_index {|value, i|
          result[i] = block.call(value)
        }
        result.par
      end

      alias_method :collect, :map
    end

    refine Enumerable do
      def par
        is_a?(ParallelEnumerable) ? self : ParallelEnumerable.new(self)
      end

      def group_by &block
        result = {}
        each {|value|
          new_key = block.call(value)
          (result[new_key] ||= []) << value
        }
        result
      end
    end

  end


  using Parallel

  # Universa network client reads current network configuration and provides access to each node independently
  # and also implement newtor-wide procedures.
  class Client

    # Create client
    # @param [PrivateKey] private_key to connect with. Generates new one if omitted.
    def initialize private_key = nil
      @connection_key = private_key
      scan_network()
    end

    # Number of accessible nodes
    def size
      @nodes.size
    end

    # private key used by the connection (might be generated)
    def private_key
      @connection_key ||= PrivateKey.new(2048)
    end

    # @return [Connection] random connection
    def random_connection
      @nodes.sample
    end

    # @return [Array(Connection)] array of count randomly selected connections
    def random_connections count = 1
      @nodes.sample(count)
    end


    private

    # Rescan the network collecting the networ map comparing results from random 70% of nodes.
    def scan_network
      # Todo: cache known nodes
      root_nodes = (1..30).map {|n| "http://node-#{n}-com.universa.io:8080/network"}

      # We scan random 70% for consensus
      n = root_nodes.size * 0.7

      candidates = {}
      root_nodes.sample(n).par.each {|path|
        retry_with_timeout(5, 3) {
          SmartHash.new(Boss.unpack open(path).read).response.nodes.each {|data|
            ni = NodeInfo.new(data)
            (candidates[ni] ||= ni).increment_rate
          }
        }
      }
      nodes = candidates.values.group_by(&:url)
                  .transform_values!(&:sort)
      # We roughly assume the full network size as:
      network_max_size = nodes.size
      # Refine result: takes most voted nodes and only these with 80% consensus
      # and map it to Connection objects
      min_rate = n * 0.8
      @nodes = nodes.values.map {|v| v[-1]}.delete_if {|v| v.rate < min_rate}
                   .map {|ni| Connection.new(self, ni)}
      raise NetworkError, "network is not ready" if @nodes.size < network_max_size * 0.9
    end
  end

  # The node information
  class NodeInfo
    attr :number, :packed_key, :url

    def initialize(data)
      @data, @number, @url, @packed_key = data, data.number, data.url, data.packed_key
      @rate = Concurrent::AtomicFixnum.new
    end

    def rate
      @rate.value
    end

    def increment_rate
      @rate.increment
    end

    def == other
      # number == other.number && packed_key == other.packed_key && url == other.url
      url == other&.url && packed_key == other&.packed_key && url == other&.url
    end

    def hash
      @url.hash + @packed_key.hash
    end

    def eql?(other)
      self == other
    end

    def < other
      rate < other.rate
    end
  end


  # Access to the single node using universa client protocol.
  #
  class Connection
    # create connection for a given clietn. Don't call it direcly, use
    # {Client.random_connection} or {Client.random_connections} instead. The client implements
    # lazy initialization so time-consuming actual connection will be postponed until
    # needed.
    #
    # @param [Client] client instance to be bound to
    # @param [NodeInfo] node_info to connect to
    def initialize(client, node_info)
      @client, @node_info = client, node_info
    end

    # executes ping. Just to ensure connection is alive. Node answers 'sping' => 'spong' hash.
    # 's' states that secure layer of client protocol is used, e.g. with mutual identification and
    # ciphering.
    def ping
      execute(:sping)
    end

    # Execute Universa Node client protocol command with optional keyword arguments that will be passed
    # to the node.
    #
    # @param [String|Symbol] name of the command
    # @return [SmartHash] with the command result
    def execute name, **kwargs
      connection.command name.to_s, *kwargs.to_a.flatten
    end

    protected

    def connection
      @connection ||= retry_with_timeout(15, 3) {
        Service.umi.instantiate "com.icodici.universa.node2.network.Client",
                                @node_info.url,
                                @client.private_key,
                                nil,
                                false
      }
    end

  end

end
