module Universa

  # A +com.icodici.crypto.PrivateKey+ extension. As the key is immutable,
  # caching is used to avoid innecessary UMI calls.
  class PrivateKey < RemoteAdapter
    remote_class 'com.icodici.crypto.PrivateKey'

    # Load key from packed, optinally, using the password
    #
    # @param [String] packed binary string with packed key
    # @param [String] password optional password
    def self.from_packed(packed, password: nil)
      packed.force_encoding 'binary'
      if password
        invoke_static "unpackWithPassword", packed, password
      else
        PrivateKey.new packed
      end
    end

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

    # sign data or string with a specified hash type
    # @return binary signature
    def sign(data, hash_type = "SHA3_384")
      __getobj__.sign(data.force_encoding('binary'), hash_type)
    end
  end

  # A +com.icodici.crypto.PublicKey+ extension. As the key is immutable,
  # caching is used to avoid unnecessary UMI calls.
  class PublicKey < RemoteAdapter
    remote_class 'com.icodici.crypto.PublicKey'

    # Load key from packed, optinally, using the password
    #
    # @param [String] packed binary string with packed key
    # @param [String] password optional password
    def self.from_packed(packed, password: nil)
      packed.force_encoding 'binary'
      if password
        invoke_static "unpackWithPassword", packed, password
      else
        PublicKey.new packed
      end
    end

    # @return [KeyAddress] short address
    def short_address
      @short_address ||= get_short_address()
    end

    # @return [KeyAddress] long address
    def long_address
      @long_address ||= get_long_address()
    end

    # Check signature
    # @param [String] data as binary or normal string
    # @param [Object] signature as binary string
    # @param [Object] hash_type to use
    # @return true if it is ok
    def verify(data, signature, hash_type = "SHA3_384")
      __getobj__.verify(data.force_encoding('binary'), signature, hash_type)
    end

    # @param [String] data binary or usual data string
    # @return [String] binary string with encrypted data
    def encrypt(data)
      __getobj__.encrypt(data.force_encoding('binary'))
    end
  end

  # A +com.icodici.crypto.SymmetricKey+ extension. As the key is immutable,
  # caching is used to avoid unnecessary UMI calls.
  class SymmetricKey < RemoteAdapter
    remote_class 'com.icodici.crypto.SymmetricKey'

    # Derive key from password using PBKDF2 standard
    # @param [String] password to derive key from
    # @param [Object] rounds derivation rounds
    # @param [Object] salt optional salt used to disallow detect password match by key match
    # @return [SymmetricKey] instance
    def self.from_password(password, rounds, salt = nil)
      salt.force_encoding(Encoding::BINARY) if salt
      invoke_static 'fromPassword', password, rounds, salt
    end

    # How many bits contains the key
    # @return [Integer] size in bits
    def size_in_bits
      @bit_strength ||= getBitStrength()
    end

    # @return [Integer] size in bytes
    def size
      @size ||= getSize()
    end

    # Get the key as binary string
    # @return [String] key bytes (binary string)
    def key
      @key ||= getKey()
    end

    # Encrypt data using EtA (HMAC)
    def eta_encrypt(plaintext)
      __getobj__.etaEncrypt(plaintext.force_encoding('binary'))
    end

    # Decrypt data using EtA (HMAC)
    def eta_decrypt(plaintext)
      __getobj__.eta_decrypt(plaintext.force_encoding('binary'))
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

    # Unpack from binary bytes
    # @param [String] binary_string with binary packed bytes
    def self.from_packed(binary_string)
      binary_string.force_encoding 'binary'
      KeyAddress.new(binary_string)
    end

    # returns binary representation. It is not a string representation!
    # @return [String] binary string representation
    def packed
      s = get_packed
      s.force_encoding 'binary'
      s
    end

    # Compare KeyAddress with another KeyAddress or its string or even binary representation.
    # Analyzes string length to select proper strategy.
    def == other
      if other.is_a?(KeyAddress)
        super
      elsif other.is_a?(String)
        case other.size
          when 37, 53
            # it is for sure packed representation
            packed == other
          else
            # is should be string representation then
            to_s == other
        end
      else
        false
      end
    end

  end

end
