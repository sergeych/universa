module Universa

  # Adapter for Universa Binder class which behaves like a ruby hash.
  class Binder < RemoteAdapter
    remote_class "net.sergeych.tools.Binder"

    # Set object for a key
    #
    # @param [Object] key key.to_s will be used (so use Symbols or Strings freely)
    # @param [Object] value
    def []=(key, value)
      __getobj__.set(key.to_s, value)
    end

    # Get object by key.
    # @param [Object] key key.to_s will be used (so use Symbols or Strings freely)
    # @return [Object] or nil
    def [](key)
      __getobj__.get(key.to_s)
    end

    # Create hew Binder from any hash. Keys will be converted to strings.
    def self.of hash
      invoke_static "of", hash.transform_keys(&:to_s)
    end

    # Retrieve binder keys
    def keys
      __getobj__.keySet()
    end

    # # Internal use only. Allow processing remote commands as local calls
    def respond_to_missing?(method_name, include_private = false)
      l = method_name[-1]
      LOCAL_METHODS.include?(method_name) || l == '!' || l == '?'
    end

    # Internal use only. Call remote method as needed. This is where all the magick comes from: it call
    # remote get/set method
    def method_missing(method_name, *args, &block)
      if respond_to_missing?(method_name, true)
        super
      else
        if method_name[-1] == '_'
          __getobj__.set(method_name[0..-1], args[0])
          args[0]
        else
          __getobj__.get(method_name)
        end
      end
    end

    LOCAL_METHODS = Set.new(%i[to_hash to_ary [] []= keys values each each_key each_with_index size map to_s])

    def to_s
      to_h.to_s
    end

    # Converts binder to the array of [key, value] pairs, like with regular ruby hashes
    def to_a
      map {|x| x}
    end

    # Enumerates all binder entries with a required block
    # @yield [key,value] pairs
    def each &block
      keys.each {|k| block.call [k, __getobj__.get(k)]}
    end

    # @return an array of values returned by the block
    # @yiekd [key,value] pairs.
    def map &block
      keys.map {|k| block.call [k, __getobj__.get(k)]}
    end

    # @return [Array(Array(String,Object))] array of [key,value] pairs.
    def to_a
      map {|x| x}
    end

    # converts to a regular ruby hash
    def to_h
      to_a.to_h
    end
  end

end

class Hash
  def to_binder
    Binder.of self
  end
end

