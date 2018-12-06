require 'boss-protocol'
require 'open-uri'
require 'concurrent'

module Universa

  using Universa

  # Universa network client reads current network configuration and provides access to each node independently
  # and also implement newtor-wide procedures.
  class Client
    using Universa::Parallel
    include Universa

    attr :connection_key

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

    def register_single contract
      random_connection.register_single contract
    end

    # Perform fats consensus state check. E.g. it scans up to 2/3 of the network until
    # the positive or negative consensus will be found. So far you can only rely on
    # result.approved? as it returns some last node result which, though, match the
    # consensus. Aggregation of parameters is under way.
    #
    # @param [Contract | HashId] obj to check
    # @return [ContractState] of some final node check It does not aggregates (yet)
    def get_state obj
      result = Concurrent::IVar.new
      negative_votes = Concurrent::AtomicFixnum.new(@nodes.size * 11 / 100)
      positive_votes = Concurrent::AtomicFixnum.new(@nodes.size * 30 / 100)
      retry_with_timeout(20, 3) {
        random_connections(@nodes.size).par.each {|conn|
          if result.incomplete?
            if (state = conn.get_state(obj)).approved?
              result.try_set(state) if positive_votes.decrement < 0
            else
              result.try_set(state) if negative_votes.decrement < 0
            end
          end
        }
        result.value
      }
    end

    # @return [Array(Connection)] array of count randomly selected connections
    def random_connections count = 1
      @nodes.sample(count)
    end

    def [] name
      @nodes.find {|x| x.url =~ /#{name}/}
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

    # constructs from binary packed data
    def initialize(data)
      @data, @number, @url, @packed_key = data, data.number, data.url, data.packed_key
      @rate = Concurrent::AtomicFixnum.new
    end

    # currently collected approval rate
    def rate
      @rate.value
    end

    # increase approval rate
    def increment_rate
      @rate.increment
    end

    # check information euqlity
    def == other
      # number == other.number && packed_key == other.packed_key && url == other.url
      url == other&.url && packed_key == other&.packed_key && url == other&.url
    end

    # allows to use as hash key
    def hash
      @url.hash + @packed_key.hash
    end

    # to use as hash key
    def eql?(other)
      self == other
    end

    # ordered by approval rate
    def < other
      rate < other.rate
    end

    def name
      @name ||= begin
        url =~ /^https{0,1}:\/\/([^:]*)/
        $1
      end
    end
  end


  # Access to the single node using universa client protocol.
  #
  class Connection
    include Universa

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

    # Register a single contract (on private network or if you have white key allowing free operations)
    # on a single node.
    #
    # @param [Contract] contract must be sealed ({Contract#seal})
    # @return [ContractState] of the result. Could contain errors.
    def register_single(contract)
      retry_with_timeout(15, 3) {
        result = ContractState.new(execute "approve", packedItem: contract.packed)
        while result.is_pending
          sleep(0.1)
          result = get_state contract
        end
        result
      }
    end

    # Get contract or hashId state from this single node
    # @param [Contract | HashId] x what to check
    # @return [ContractState]
    def get_state x
      id = case x
             when HashId
               x
             when Contract
               x.hash_id
             else
               raise ArgumentError, "bad argument, want Contract or HashId"
           end
      ContractState.new(execute "getState", itemId: id)
    end


    # Execute Universa Node client protocol command with optional keyword arguments that will be passed
    # to the node.
    #
    # @param [String|Symbol] name of the command
    # @param kwargs arguments to call
    # @return [SmartHash] with the command result
    def execute(name, **kwargs)
      connection.command name.to_s, *kwargs.to_a.flatten
    end

    # def stats days=0
    #   connection.getStats(days.to_i)
    # end

    def url
      @node_info.url
    end

    def name
      @node_info.name
    end

    def number
      @node_info.number
    end

    def to_s
      "Conn<#{@node_info.url}>"
    end

    def inspect
      to_s
    end

    protected

    def connection
      @connection ||= retry_with_timeout(15, 3) {
        conn = Service.umi.instantiate("com.icodici.universa.node2.network.Client",
                                       @node_info.url,
                                       @client.private_key,
                                       nil,
                                       false)
                   .getClient(@node_info.number - 1)
        conn
      }
    end

  end

  class ContractState
    def initialize(universa_contract_state)
      @source = universa_contract_state
    end

    def errors
      @source.errors&.map &:to_s
    rescue
      "failed to extract errors: #$!"
    end

    def state
      @source.itemResult.state
    end

    def is_pending
      state.start_with?('PENDING')
    end

    def is_approved
      case state
        when 'APPROVED', 'LOCKED'
          true
        else
          false
      end
    end

    def approved?
      is_approved
    end

    def pending?
      is_pending
    end

    def to_s
      "ContractState:#{state}"
    end

    def inspect
      to_s
    end
  end

end
