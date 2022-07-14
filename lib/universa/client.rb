require 'boss-protocol'
require 'open-uri'
require 'concurrent'

module Universa

  # The low-level adapter for the UMI Universa client. We provide convenience wrappers for it
  # {Client} and {Connection} classes, more rubyish in interface paradigm, so there is no need to use it directly.
  class UmiClient < RemoteAdapter
    remote_class "com.icodici.universa.node2.network.Client"
  end

  # The universa network client. Discover and connects to the universa network, provides consensus operations
  # and all other whole-network related functions.
  class Client
    using Universa::Parallel
    include Universa

    # Discovered network size
    attr :size

    # Client private key ised in the connection
    attr :private_key

    # Construct an Universa network client. Bu default, connects to the main network. Perform consensus-based
    # network scanning and saves the current network topology in the cache on the file system, default is under
    # +~/.universa+ but could be overriden.
    #
    # If the network topology file is presented but the cached topology is newer, the cached will be used.
    #
    # The client accepts small network topology changes as long as it still create consensus. Still, too big changes
    # in the network topology might require fresh topology file (or upgrade the gem).
    #
    #
    # @param [String] topology could be name of known network (e.g. mainnet as by default) or path to a .json file
    #                 containing some network topology, for example, obtained from some external source like telegram
    #                 channel.
    # @param [PrivateKey] private_key to connect with.
    # @param [String] cache_dir where to store resulting topology. we recommend to leave it as nil.
    #
    # @raise if network topology could not be checked/obtained.
    def initialize topology: "mainnet", private_key: PrivateKey.new(2048), cache_dir: nil
      @client = UmiClient.new topology, cache_dir, private_key
      @private_key = private_key
      @size = @client.size
      @connections = (0...@size).map { nil }
    end

    # Get the node connection by its index (0...size).
    # @return [Connection] object
    def [] index
      raise IndexError if index < 0 || index >= @size
      @connections[index] ||= Connection.new(@client.getClient(index))
    end

    # Get the random node connection
    # @return [Connection] node connection
    def random_connection
      self[rand(0...size)]
    end

    # Get several random connections
    # @param [Numeric] number of connections to get
    # @return [Array(Connection)] array of connections to random (non repeating) nodes
    def random_connections number
      (0...size).to_a.sample(number).map { |n| self[n] }
    end

    # Perform fast consensus state check with a given trust level, determining whether the item is approved or not.
    # Blocks for 1 minute or until the network solution will be collected for a given trust level.
    #
    # @param [Contract | HashId | String | Binary] obj contract to check
    # @param [Object] trust level, should be between 0.1 (10% of network) and 0.9 (90% of the network)
    # @return true if the contract state is approved by the network with a given trust level, false otherwise.
    def is_approved? obj, trust: 0.3
      hash_id = case obj
                  when HashId
                    obj
                  when Contract
                    obj.hash_id
                  when String
                    if obj.encoding == Encoding::ASCII_8BIT
                      HashId.from_digest(obj)
                    else
                      HashId.from_string(obj)
                    end
                  else
                    raise ArgumentError "wrong type of object to check approval"
                end
      @client.isApprovedByNetwork(hash_id, trust.to_f, 60000)
    end

    # Perform fast consensus state check with a given trust level, as the fraction of the whole network size.
    # It checks the network nodes randomly until get enough positive or negative states. The lover the required
    # trust level is, the faster the answer will be found.
    #
    # @param [Contract | HashId] obj contract to check
    # @param [Object] trust level, should be between 0.1 (10% of network) and 0.9 (90% of the network)
    # @return [ContractState] of some final node check It does not calculates average time (yet)
    # @raise Error if any of the queried nodes will cause an error.
    def get_state obj, trust: 0.3
      raise ArgumentError, "trust must be in 0.1..0.9 range" if trust < 0.1 || trust > 0.9
      result = Concurrent::IVar.new
      found_error = nil
      negative_votes = Concurrent::AtomicFixnum.new((size * 0.1).round + 1)
      positive_votes = Concurrent::AtomicFixnum.new((size * trust).round)

      # consensus-finding conveyor: we chek connections in batches in parallel until get
      # some consensus. We do not wait until all of them will answer
      (0...size).to_a.shuffle.each { |index|
        Thread.start {
          if result.incomplete?
            begin
              if (state = self[index].get_state(obj)).approved?
                result.try_set(state) if positive_votes.decrement < 0
              else
                result.try_set(state) if negative_votes.decrement < 0
              end
            rescue
              found_error = $!
              result.try_set(nil)
            end
          end
        }
      }
      r = result.value
      found_error != nil and raise found_error
      r
    end

    # Register a single contract (on private network or if you have white key allowing free operations)
    # on a random node. Client must check returned contract state. It requires "open" network or special
    # key that has a right to register contracts without payment.
    #
    # When retrying, randpm nodes are selected.
    #
    # @param [Contract] contract must be sealed ({Contract#seal})
    #
    # @return [ContractState] of the result. Could contain errors.
    def register_single(contract, timeout: 45, max_retries: 3)
      retry_with_timeout(timeout, max_retries) {
        ContractState.new(random_connection.register_single(contract, timeout / max_retries * 1000 - 100))
      }
    end

  end

  # The connection to a single Universa node.
  class Connection

    # Do not create it directly, use {Client#random_connection}, {Client#random_connections} or {Client#[]} instead
    def initialize umi_client
      @client = umi_client
    end

    def umi_client
      @client
    end

    def node_number
      @node_number ||= @client.getNodeNumber()
    end

    # ping another node from this one
    #
    # @param [Numeric] node_number to ping
    # @param [Numeric] timeout
    #
    # @return [Hash] hashie with TCP and UDP fields holding ping time in millis, -1 if not available
    def ping_node(node_number, timeout: 5000)
      Hashie::Mash.new(@client.pingNode(node_number, timeout).to_h)
    end

    # Check the connected node is alive. It is adivesd to call {restart} on nodes that return false on pings
    # to reestablish connection.
    #
    # @return true if it is ok
    def ping
      @client.ping
    end

    # Attempt to reestablish connection to the node
    def restart
      @client.restart
    end

    # node url (IP-based)
    def url
      @url ||= @client.get_url
    end

    # Register a single contract (on private network or if you have white key allowing free operations)
    # with the current  node. Client must check returned contract state. It requires "open" network or special
    # key that has a right to register contracts without payment.
    #
    # @param [Contract] contract must be sealed ({Contract#seal})
    #
    # @return [ContractState] of the result. Could contain errors.
    def register_single(contract, timeout = 25)
      ContractState.new(@client.register(contract.packed, timeout * 1000))
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
      ContractState.new(@client.getState(id))
    end

    def inspect
      "<Universa::Connection:#{url}"
    end

    def to_s
      inspect
    end

  end

  # The state of some contract reported by the network. It is a convenience wrapper around Universa
  # ItemState structure.
  class ContractState
    def initialize(universa_contract_state)
      @source = universa_contract_state
    end

    # get errors reported by the network
    # @return [Array(Hash)] possibly empty array of error data
    def errors
      @_errors ||= @source.errors || []
    rescue
      "failed to extract errors: #$!"
    end

    # @return true if the state contain errors
    def errors?
      !errors.empty?
    end

    # @return ItemState structure reported by the UMI
    def state
      @source.state
    end

    # Check that state us +PENDING+. Pending state is neither approved nor rejected.
    # @return true if this state is one of the +PENDING+ states
    def is_pending
      state.start_with?('PENDING')
    end

    # @return true if the contract state was approved
    def is_approved
      case state
        when 'APPROVED', 'LOCKED'
          true
        else
          false
      end
    end

    # same as {is_approved}
    def approved?
      is_approved
    end

    # same as {is_pending}
    def pending?
      is_pending
    end

    def to_s
      "<ContractState:#{state}>"
    end

    def inspect
      to_s
    end
  end

end
