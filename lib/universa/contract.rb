module Universa

  # Adapter for Universa ChangeOwnerPermission
  class ChangeOwnerPermission < RemoteAdapter
    remote_class "com.icodici.universa.contract.permissions.ChangeOwnerPermission"
  end

  # Adapter for Universa RevokePermission
  class RevokePermission < RemoteAdapter
    remote_class "com.icodici.universa.contract.permissions.RevokePermission"
  end

  class SplitJoinPermission < RemoteAdapter
    remote_class "com.icodici.universa.contract.permissions.SplitJoinPermission"
  end

  # Adapter for Universa Role
  class Role < RemoteAdapter
    remote_class "com.icodici.universa.contract.roles.Role"
  end

  # Adapter for Universa Binder class. Provides some ruby-style helpers
  class Binder < RemoteAdapter
    remote_class "net.sergeych.tools.Binder"

    # Set object for a key
    #
    # @param [Object] key key.to_s will be used (so use Symbols or Strings freely)
    # @param [Object] value
    def []=(key, value)
      set(key.to_s, value)
    end

    # Get object by key.
    # @param [Object] key key.to_s will be used (so use Symbols or Strings freely)
    # @return [Object] or nil
    def [](key)
      get(key.to_s)
    end

    def self.of hash
      invoke_static "of", hash.transform_keys(&:to_s)
    end

    # def metohd_missing?
    #
    # end
  end

  # Adapter for Universa +HashId+ class, helps to avoid confusion when using different
  # representations of the ID.
  class HashId < RemoteAdapter
    remote_class "com.icodici.universa.HashId"

    # Construct from binary representation, not to confuse with binary one.
    #
    # @param [String] digest_bytes binary string of some +hash_id.bytes+
    # @return [HashId] instance with instance.bytes == digest.bytes
    def self.from_digest(digest_bytes)
      digest_bytes.force_encoding 'binary'
      invoke_static 'with_digest', digest_bytes
    end

    # Construct from string representation of the ID, not to confuse with binary one.
    #
    # @param [String] string_id id string representation, like from +hash_id_instance.to_s+. See {#to_s}.
    def self.from_string(string_id)
      string_id.force_encoding 'utf-8'
      invoke_static 'with_digest', string_id
    end

    # Get binary representation. It is shorter than string representation but contain non-printable characters and
    # can cause problems if treated like a string. Use {#to_s} to get string representation instead.
    #
    # @return [String] binary string
    def bytes
      get_digest
    end

    # Get string representation. It is, actually, base64 encoded string representation. Longer, but could easily
    # be transferred with text protocols.
    #
    # @return [String] string representation
    def to_s
      Base64.encode64(get_digest).gsub(/\s/, '')
    end
  end

  # Universa contract adapter.
  class Contract < RemoteAdapter
    remote_class "com.icodici.universa.contract.Contract"

    # Create simple contract with preset critical parts:
    #
    # - expiration set to 90 days unless specified else
    # - issuer role is set to the address of the issuer key, short ot long
    # - creator role is set as link to issuer
    # - owner role is set as link to issuer
    # - change owner permission is set to link to owner
    #
    # The while contract is then signed by the issuer key. Not that it will not seal it: caller almost always
    # will add more data before it, then must call #seal().
    #
    # @param [PrivateKey] issuer_key also will be used to sign it
    # @param [Time] expires_at defaults to 90 days
    # @param [Boolean] use_short_address set to true to use short address of the issuer key in the role
    # @return [Contract] simple contact, not sealed
    def self.create issuer_key, expires_at: (Time.now + 90 * 24 * 60 * 60), use_short_address: false
      contract = Contract.new
      contract.set_expires_at expires_at
      contract.set_issuer_keys(use_short_address ? issuer_key.short_address : issuer_key.long_address)
      contract.register_role(contract.issuer.link_as("owner"))
      contract.register_role(contract.issuer.link_as("creator"))
      contract.add_permission ChangeOwnerPermission.new(contract.owner.link_as "@owner")
      contract.add_permission RevokePermission.new(contract.owner.link_as "@owner")
      contract.add_signer_key issuer_key
      contract
    end

    # Load from transaction pack
    def self.from_packed packed
      packed.force_encoding 'binary'
      self.invoke_static "fromPackedTransaction", packed
    end

    # seal the contract
    # @return [String] contract packed to the binary string
    def seal
      super
    end

    # returns keys that will be used to sign this contract on next {seal}.
    # @return [Set<PrivateKey>] set of private keys
    def keys_to_sign_with
      get_keys_to_sign_with
    end

    # Shortcut ofr get_creator
    # @return [Role] universa role of the creator
    def creator
      get_creator
    end

    # @return [Role] issuer role
    def issuer
      get_issuer
    end

    # @return [Role] owner role
    def owner
      get_owner
    end

    def owner= key
      set_owner_key key
    end

    # Shortcut for is_ok
    def ok?
      is_ok
    end

    # shortcut for getHashId
    def hash_id
      get_id
    end

    # shortcut for get_expires_at
    def expires_at
      get_expires_at
    end

    def expires_at= time
      set_expires_at time
    end

    # @return definition data
    def definition
      @definition ||= get_definition.get_data
    end

    def state
      @state ||= getStateData()
    end

    # Get +transactional.data+ section creating it if need
    # @return [Binder] instance
    def transactional
      @transactional ||= getTransactionalData()
    end

    # def transactional?
    #   !!getTransactional()
    # end

    # Helper for many token-like contracts containing state.data.amount
    # @return [BigDecimal] amount or nil
    def amount
      v = state[:amount] and BigDecimal(v.to_s)
    end

    # Write helper for many token-like contracts containing state.data.amount. Saves value
    # in state.data.anomount and properly encodes it so it will be preserved on packing.
    #
    # @param [Object] value, should be some representation of a number (also string)
    def amount= (value)
      state[:amount] = value.to_s.force_encoding('utf-8')
    end

    # Get packed transaction containing the serialized signed contract and all its counterparts.
    # Be sure to cal {#seal} somewhere before.
    #
    # @return binary string with packed transaction.
    def packed
      get_packed_transaction
    end

    # trace found errors (call it afer check()): the Java version will not be able to trace to the
    # process stdout, so we reqrite it here
    def trace_errors
      getErrors.each {|e|
        puts "(#{e.object || ''}): #{e.error}"
      }
    end

    # Call it after check to get summaru of errors found.
    #
    # @return [String] possibly empty ''
    def errors_string
      getErrors.map {|e|  "(#{e.object || ''}): #{e.error}"}.join(', ').strip
    end

    def can_perform_role name, *keys
      getRole(name.to_s).isAllowedForKeys(Set.new keys.map{ |x|
        x.is_a?(PrivateKey) ? x.public_key : x
      })
    end

    # def create_revocation *keys
      # Service.umi.invoke_static 'ContractService', 'createRevocation', *keyss
      # sel
    # end

  end

end