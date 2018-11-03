module Universa

  # A +com.icodici.crypto.PrivateKey+ extension. As the key is immutable,
  # caching is used to avoid innecessary UMI calls.
  class PrivateKey < RemoteAdapter
    remote_class 'com.icodici.crypto.PrivateKey'

    # @return [KeyAddress] short address of the corresponding public key
    def short_address
      @short_address ||= public_key.short_address
    end

    # @return [KeyAddress] long address of the corresponding public key
    def long_address
      @long_address ||= public_key.long_address
    end

    # @return [PublicKey] public key that matches this
    def public_key
      @public_key ||= get_public_key
    end
  end

  # A +com.icodici.crypto.PublicKey+ extension. As the key is immutable,
  # caching is used to avoid innecessary UMI calls.
  class PublicKey < RemoteAdapter
    remote_class 'com.icodici.crypto.PublicKey'

    # @return [KeyAddress] short address
    def short_address
      @short_address ||= get_short_address()
    end

    # @return [KeyAddress] long address
    def long_address
      @long_address ||= get_long_address()
    end
  end

  # The +com.icodici.crypto.KeyAddress+ extension. As it is immutable, caching is
  # used to avoid unnecessary UMI calls.
  class KeyAddress < RemoteAdapter
    remote_class 'com.icodici.crypto.KeyAddress'

    # String form of the key which could be used to unpack it back
    # @return [String] packed string representation
    def to_s
      @string ||= toString()
    end
  end

end
