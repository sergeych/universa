module Universa

  # under construction, pls on not use yet
  #
  # this is a base class for a contract stored in some contract chain. The implementation
  # must inherit and implement its {#load} and {#save} methods at least. To do it,
  # inherit and implement {ChainStore} to work with it.
  #
  # Notable features:
  #
  # - contract could be assigned only once, no matter how, so its fields could be cached.
  # - origin, hash_id and parent are cached. So other contract parameters should be.
  #
  class StoredContractBase

    # {ChainStore} instance to which it is connected
    attr :chain_store
    # {Contract} instance stored in it. Can be lazy-loaded
    attr :contract
    # {HashId} of the {#contract}
    attr :hash_id

    # @return [HashId] {#contract}.origin. See {Contract#origin}
    def origin
      @origin ||= @contract.origin
    end

    # @return [HashId] {#contract}.origin. See {Contract#parent}
    def parent
      @parent ||= @contract.parent
    end

    # Construct implementation connected to a given store
    # @param [ChainStore] chain_store descendant class
    def initialize(chain_store)
      @chain_store = chain_store
      @chain_store.is_a?(ChainStore) or raise ArgumentError, "ChainStore instance required"
      @chain_store = chain_store
    end

    # For implementation logic, in particular, to make lazy loads.
    # @return true if the stored contract is loaded into this instance
    def has_contract?
      !@contract.nil?
    end

    # Shortcut for `contract.packed`. See {Contract#packed}
    # @return [String] binary string with contained contract packed transaction.
    def packed_contract
      @contract.packed
    end

    # override it to save the contract in the connected contract chain.
    def save
      raise NotFoundError
    end

    # override it to load the contract from the connected contract chain.
    def load hash_id
      raise NotFoundError
    end

    # Assign contract to the instance.
    # @param [Contracy] new_contract to store
    def contract=(new_contract)
      raise IllegalStateError, "contract can't be reassigned" if has_contract?
      @contract = new_contract
      @hash_id = @contract.hash_id
      @origin = @parent = nil
    end

    # Convenience method. Unoacks and stores the contract.
    def packed_contract=(new_packed_contract)
      self.contract = Contract.from_packed(new_packed_contract)
    end

  end
end