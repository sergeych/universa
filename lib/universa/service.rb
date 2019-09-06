require 'singleton'

module Universa

  # The service is a singleton to provide porcess-wide objects and methods. For example,
  # the {UMI} interface and reference class factory are unique per-process for Universa
  # library. It uses exactly one lazy created {UMI} connection which is shared among all threads.
  # As UMI server is multithreaded by nature, is will not block ruby threads waiting for remote
  # invocation.
  class Service

    @@log_umi = false

    # set log mode for UMI commands. Works only when called before any Service usage, e.g. before the
    # UMI client has been constructed.
    def self.log_umi
      @@log_umi = true
    end

    include Singleton

    # Setup service initial parameters
    def initialize
      @config = SmartHash.new path: nil
      @@log_umi && @config['log'] = 'umi.log'
      @known_proxies = {}
      [Contract, PrivateKey, PublicKey, KeyAddress, HashId, Binder,
       Role, SimpleRole, RoleLink, ListRole, Parcel, UnsContract,
       ChangeOwnerPermission, RevokePermission, ModifyDataPermission,  SplitJoinPermission,
       UmiClient, Duration, Compound, KeyInfo, PBKDF2].each {|klass| register_proxy klass}
    end

    # Implementation of {Service.configure}
    def configure &block
      raise Error, "config call must happen before interface creation" if @umi
      block.call @config
    end

    # Implementation of {Service.umi}
    def umi
      c = @config.to_h.transform_keys(&:to_sym).update(convert_case: true)
      c[:factory] = -> (ref) {create_proxy(ref)}
      @umi ||= UMI.new(c.delete(:path), **c)
    end


    # push string to service log
    def log msg
      puts "U:Service: #{msg}"
    end

    # Create object proxy for known types
    # @param [Ref] ref to transform
    # @return [RemoteAdapter | Ref] transformed or source reference
    def create_proxy ref
      proxy_class = @known_proxies[ref._remote_class_name]
      return ref unless proxy_class
      proxy_class.new(ReferenceCreationData.new(ref))
    end

    class << self

      # Call it before everything to update UMI interface parameters before is is created.
      # Calling it when UMI is already constructed raises Error.
      def configure &block
        instance.configure &block
      end

      # Get the global UMI interface, creating it if need.
      # @return [UMI] ready interface
      def umi
        instance.umi
      end
    end

    # Register a class that will work as a proxy for UMI remote class. Such adapter class mist extend RemoteAdapter
    # class. Once the class is registered, serive will automatically instantiate it when UMI will pass the instance
    # of the corresponding remote class.
    # @param [Class] klass that will be
    def register_proxy(klass)
      klass < RemoteAdapter or raise ArgumentError, "#{klass.name} must be based on RemoteAdapter"
      remote_class_name = klass.remote_class_name
      raise Error, "#{remote_class_name} is already registered in Service" if @known_proxies.include?(remote_class_name)
      @known_proxies[remote_class_name] = klass
    end
  end

  # The basic class to write remote class adapters (extensions). Delegates contained {Ref} instance therefore behaves
  # like remote interface with some extensions.
  #
  # Key feature of RemoteAdapter class is the cross-call persistence. It means once created instances of the
  # RemoteAdapter descendants are cached just like (in fact, instead of) {Ref} instances, so  when the remote party
  # returns the reference to the object once wrapped by this instance, the instance will be returned unless it is
  # already garbage collected. instance will be returned, what means sort of cross-platform calls persistence.
  #
  # Extending this class normally should not implement the constructor, By defaul the constructor is passed to
  # the remote to create remote instance.
  class RemoteAdapter < Delegator

    # Instantiate new proxy object passing arguments to the remote constructor. The UMI host will try
    # to find overloaded constructor that matches the arguments.
    #
    # @param [*Any] args any arguments that remote constructor may accept.
    def initialize(*args)
      if args.length == 1 && args[0].is_a?(ReferenceCreationData)
        @remote = args[0].ref
      else
        # User called constructor
        remote_class_name = self.class.remote_class_name
        remote_class_name&.length or raise Error, "provide remote_class_name"
        @remote = Service.umi.instantiate remote_class_name, *args, adapter: self
      end
    end

    # Delegated object
    # @return [Ref] the wrapped instance whose methpds are delegated by this
    def __getobj__
      @remote
    end

    # Updating proxied object is not allowed. Raises error.
    def __setobj__
      raise "ObectProxy does not support changing referenced object"
    end

    # Returns remote class name. There is no need to override it, when inheriting it use +remote_class+ helper:
    #
    #   class MyKeyAddress < ObjectProxy
    #      remote_class 'com.icodici.crypto.KeyAddress'
    #
    #      #...
    #   end
    #
    # Notice: remote_class will do allnecessary work for you.
    #
    # @return [String] remote class name
    def self.remote_class_name
      @remote_class_name or raise Error, "provde remote class name"
    end

    # Registers remote class name to be used with this adapted. Call it early in descendant class
    # declaration.
    def self.remote_class name
      @remote_class_name = name
    end

    # debugging label
    def inspect
      "<#{self.class.name}:#{__id__}:#{@remote._remote_class_name}:#{@remote._remote_id}>"
    end

    # call the remote toString(). Does not cache it.
    # @return [String]
    def to_s
      toString()
    end

    def self.invoke_static(method_name, *args)
      Service.umi.invoke_static @remote_class_name, method_name, *args
    end

    def self.remote_field *names
      names.each {|name|
        class_eval <<-End
          def #{name}
            Service.umi.get_field(self,"#{name}")
          end
          def #{name}=(value)
            Service.umi.set_field(self,"#{name}", value)
          end
          End
      }
    end

    def self.static_method name
      class_eval <<-End
        def self.#{name} *args
          invoke_static "#{name.to_s}", *args
        end
      End
    end
  end

end
