module Universa

  # Universa contract adapter.
  class Contract < RemoteAdapter
    remote_class "com.icodici.universa.contract.Contract"

    # seal the contract
    # @return [String] contract packed to the binary string
    def seal
      super
    end

    # returns keys that will be used to sign this contract on next {seal}.
    # @return [Set<PrivateKey>] set of private keys
    def signing_keys
      get_keys_to_sign_with
    end
  end

end