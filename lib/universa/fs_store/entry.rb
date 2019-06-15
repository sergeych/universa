module Universa::FSStore

  # The {StoredContract} implementation to work with {FileStore}.
  #
  # @!method name
  #   @return [String] the +contract.definition.data.name+ value or nil.
  #
  # @!method currency
  #   @return [String] the +contract.definition.data.currency+ value or nil.
  #
  # @!method amount
  #   @return [BigDecimal] +contract.state.data.amount+ or nil. See {Contract#amount} for more.
  #
  class Entry < Universa::StoredContractBase

    extend Forwardable

    # (see StoredContract#load)
    def load(hash_id)
      init_with_hash_id hash_id
      self
    end

    # initialize new instance with an existing contract
    # @param [Contract] contract to store
    def init_with_contract(contract)
      self.contract = contract
      self
    end

    # initialize new instance with attributes YAML file
    # @param [String] file_name of the +.unicon.yaml+ file
    def load_from_yaml_file(file_name)
      init_with_yaml_file_name file_name
      self
    end

    # (see StoredContract#hash_id)
    def hash_id
      @id
    end

    # (see StoredContract#contract=)
    def contract= new_contract
      @id = new_contract.hash_id
      prepare_file_names
      super
      # we will always rewrite existing file to be sure it is correct
      open(@file_name, 'wb') {|f| f << contract.packed}
      # now we are to extract and rewrite attributes
      load_attributes_from_contract # it will save them too
    end

    # Implement lazy load logic
    # @return [Contract] instance loaded at first call only
    def contract
      # load it if it is not
      self.packed_contract = open(@file_name, 'rb') {|f| f.read} unless has_contract?
      # @attributes must already be set
      super
    end

    def_delegators :@attributes, :name, :currency, :amount

    protected

    # initialize instance for an existing file. Should be a contract already stored in the connected store.
    # @param [Object] hash_id to construct from
    def init_with_hash_id(hash_id)
      raise IllegalStateError, "already initialized" if @id
      @id = hash_id
      prepare_file_names
      load_attributes_from_file
      # attrs are already in the file so we need not to save them
    end

    # Load from attributes file name
    def init_with_yaml_file_name file_name
      @attr_file_name = file_name
      load_attributes_from_file
      prepare_file_names
    end

    # save attributes to .yaml file
    def save_attributes
      open(@attr_file_name, 'w') {|f| YAML.dump(@attributes, f)}
    end

    # load attributes from a contract (already assigned) and store them in the .yaml file
    def load_attributes_from_contract
      state = contract.state
      definition = contract.definition
      @attributes = SmartHash.new({
                                      id: hash_id.to_s,
                                      parent: parent&.to_s,
                                      origin: origin.to_s,
                                      name: definition.name,
                                      currency: definition.currency,
                                      amount: state.amount
                                  })
      save_attributes
    end

    # load attributes from the .yaml file
    def load_attributes_from_file
      @attributes = SmartHash.new(YAML.load_file(@attr_file_name))
      @id = HashId.from_string @attributes.id
    end

    # prepare file name fields (@file_name and @attr_file_name)
    # @param [HashId] hash_id or ni to use one already set in @id
    def prepare_file_names(hash_id = nil)
      @file_name = "#{chain_store.root}/#{@id.to_url_safe_string[0..27]}.unicon"
      @attr_file_name = "#@file_name.yaml"
    end
  end

end