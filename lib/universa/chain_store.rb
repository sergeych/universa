require 'yaml'

module Universa

  # Work iun progress, not to use as for now.
  #
  # The storage interface capable to store contracts in chains, providing search and attributes.
  # This class is not a store itself but the base class for it, having common boilerplate and
  # sort of interface to implement. _Under development, we might change it_
  class ChainStore

    # Save contract to the store. When this method returns, the contract must me already stored.
    # If the contract with such hasId is already stored, just returns it.
    #
    # @param [Object] contract to store
    # @return [StoredContract] for this contract
    def store_contract(contract)
      raise NotImplementedError
    end

    # Same as {#store_contract} but returns store
    # @param [Contract] contract to add
    # @return [ChainStore] self
    def <<(contract)
      store_contract(contract)
      self
    end

    # @return [Contract] with the corresponding id or nil
    # @param [HashId] hash_id instance to look for
    def find_by_id(hash_id)
      raise NotImplementedError
    end

    # Count contracts in the store. This operation could be slow.
    def count
      raise NotImplementedError
    end

    # @return [Contract] with the corresponding id or raise.
    # @param [HashId] hash_id instance to look for
    # @raise [NotFoundError]
    def find_by_id! hash_id
      find_by_id(hash_id) or raise NotFoundError
    end

    # Find all contracts with this parent id.
    # @param [HashId] hash_id of the parent contract
    # @return [Array] all the contracts that match this criterion
    def find_by_parent(hash_id)
      raise NotImplementedError
    end

  end

end