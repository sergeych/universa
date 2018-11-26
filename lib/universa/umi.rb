require 'open3'
require 'farcall'
require 'set'
require 'base64'
require 'weakref'
require_relative 'weak_reference'

using Universa

module Universa

  # Universa Method Invocation remote interface.
  #
  # By default, it creates UMI interface to the included UMI server which gives almost full access
  # to the Universa Java API:
  #
  # Uasge:
  #    >> umi = Universa::UMI.new()
  #    >> # create a new key and new contract with this key as creator:
  #    >> contract = umi.instantiate "Contract", umi.instantiate("PrivateKey", 2048)
  #
  # Use {#instantiate} to create new instances of remote classes, which return {Ref} instances,
  # and just call their methods as if these are usual ruby methods. For example in the example above:
  #
  #    address = contract.getKeysToSignWith()[0].getPublicKey().getShortAddress().toString()
  #
  # In the sample above all the methods are called on the remote side, returning links to remote objects
  # which are all {Ref} instances, and the last `toString()` call return a string, which is converted to
  # ruby string and saved into variable. This sentence, therefore, get the first signer key and transofrms it
  # to the string short address.
  #
  # == Having several `UMI` interfaces.
  #
  # It is possible to have several UMI instances, by default, it will create separate process with isolated
  # data space, which is perfectly safe to use in various scenarios.
  #
  # It still means the object from different interfaces can't be interchanged. {Ref} instances created
  # by one interface should be used with this interface only, or the {InterchangeError} will be raised.
  #
  # == Remote exceptions
  #
  # If remote part will thow an Exception performing a method, it will be raised as an instance of
  # {https://www.rubydoc.info/gems/farcall/Farcall/RemoteError Farcall::RemoteError} class which carries remote
  # exception information.
  #
  # == Transport level
  #
  # UMI uses {https://github.com/sergeych/farcall/wiki Farcall} transport in woth JSON adapter and "\n" as separator.
  #
  class UMI

    ##
    # Create UMI instance. It starts the private child process wit UMI server and securely connects to
    # it so no other connection could occur.
    #
    #    # create UNI interface
    #    umi = Universa::UMI.new()
    #    # create a new key and new contract with this key as creator:
    #    contract = umi.instantiate "Contract", umi.instantiate("PrivateKey", 2048)
    #    contract.seal()  # binary packed string returned
    #    contract.check() #=> true
    #
    # @param [String] path to custom UMI server build. Use bundled one (leave as nil)
    # @param [Regexp] version_check check version against
    # @param [String] system expected on the remote side. 'UMI' us a universa umi server.
    # @param [Boolean] convert_case it true, convert ruby style snake case `get_some_stuff()` to java style lower camel
    #                  case `getSomeStuff()` while calling methods. Does not affect class names on {instantiate}.
    def initialize(path = nil, version_check: /./, system: "UMI", log: 'sessionlog.txt', convert_case: true, factory: nil)
      path ||= File.expand_path(File.split(__FILE__)[0] + "/../../bin/umi/bin/umi")
      @in, @out, @err, @wtr = Open3.popen3("#{path} #{log ? "-log #{log}" : ''}")
      @endpoint = Farcall::Endpoint.new(
          Farcall::JsonTransport.create(delimiter: "\n", input: @out, output: @in)
      )
      @lock = Monitor.new
      @cache = {}
      @closed = false
      @convert_case, @factory = convert_case, factory
      @references = {}
      start_cleanup_queue
      @version = call("version")
      raise Error, "Unsupported system: #{@version}" if @version.system != "UMI"
      raise Error, "Unsupported version: #{@version}" if @version.version !~ /0\.8\.\d+/
    rescue Errno::ENOENT
      @err and STDERR.puts @err.read
      raise Error, "missing java binaries"
    end

    # @return version of the connected UMI server. It is different from the gem version.
    def version
      @version.version
    end

    # Create instance of some Universa Java API class, for example 'Contract', passing any arguments
    # to its constructor. The returned reference could be used much like local instance, nu the actual
    # work will happen in the child process. Use references as much as possible as they take all the
    # housekeeping required, like memory leaks prevention and direct method calling.
    #
    # @return [Ref] reference to the remotely created object. See {Ref}.
    def instantiate(object_class_name, *args, adapter: nil)
      ensure_open
      create_reference call("instantiate", object_class_name, *prepare_args(args)), adapter
    end

    # Invoke method by name. Should not be used directly; use {Ref} instance to call its methods.
    def invoke(ref, method, *args)
      ensure_open
      ref._umi == self or raise InterchangeError
      @convert_case and method = method.to_s.camelize_lower
      # p ["invoke", ref._remote_id, method, *prepare_args(args)]
      result = call("invoke", ref._remote_id, method, *prepare_args(args))
      encode_result result
    end

    def invoke_static(class_name, method, *args)
      encode_result call("invoke", class_name, method, *prepare_args(args))
    end

    # Close child process. No remote calls should occur after it.
    def close
      @queue.push :poison_pill
      @cleanup_thread.join
      @closed = true
      @endpoint.close
      @in.close
      @out.close
      @wtr.value.exited?
    end

    # short data label for UMI interface
    def inspect
      "<UMI:#{__id__}:#{version}>"
    end

    # debug use only. Looks for the cached e.g. (alive) remote object. Does not check
    # the remote side.
    def find_by_remote_id remote_id
      @lock.synchronize {@cache[remote_id]&.get}
    end

    # Execute the block with trace mode on. Will spam the output with protocol information.
    # These calls could be nested, on exit it restores previous trace state
    def with_trace &block
      current_state, @trace = @trace, true
      result = block.call()
      @trace = current_state
      result
    end

    private

    # create a finalizer that will drop remote object
    def create_finalizer(remote_id)
      -> (id) {
        begin
          @lock.synchronize {
            @cache.delete(remote_id)
            # log "=== removing remote ref #{id} -> #{remote_id}"
            @queue.push(remote_id)
          }
        rescue ThreadError
          # can't be called from trap contect - life is life ;)
          # silently ignore
        rescue
          $!.print_stack_trace
        end
      }
    end

    # Create a reference correcting adapting remote types to ruby ecosystem, for example loads
    # remote Java Set to a local ruby Set.
    def create_reference(reference_record, adapter = nil)
      r = build_reference reference_record, adapter
      return r if adapter
      case reference_record.className
        when 'java.util.HashSet'
          r.toArray()
        else
          r
      end
    end

    # Create a reference from UMI remote object reference structure. Returns existing object if any. Takes care
    # of dropping remote object when ruby object gets collected.
    def build_reference(reference_record, proxy)
      @lock.synchronize {
        remote_id = reference_record.id
        ref = @cache[remote_id]&.get
        if !ref
          # log "Creating new reference to remote #{remote_id}"
          ref = Ref.new(self, reference_record)
          # IF we provide proxy that will consume the ref, we'll cache the proxy object,
          # otherwise we run factory and cahce whatever it returns or the ref itself
          obj = if proxy
                  # Proxy object will delegate the ref we return from there
                  # no action need
                  proxy
                else
                  # new object: factory may create proxy for us and we'll cache it for later
                  # use:
                  @factory and ref = @factory.call(ref)
                  ref
                end
          # Important: we set finalizer fot the target object
          ObjectSpace.define_finalizer(obj, create_finalizer(remote_id))
          # and we cache target object
          @cache[remote_id] = WeakReference.new(obj)
        end
        # but we return reference: it the proxy constructor calls us, it'll need the ref:
        ref
      }
    end

    # Start the remote object drop queue processing.
    def start_cleanup_queue
      return if @queue
      @queue = Queue.new
      @cleanup_thread = Thread.start {
        while (!@closed)
          id = @queue.pop()
          if id == :poison_pill
            # log "leaving cleanup queue"
            break
          else
            begin
              call("drop_objects", id)
                # log "remote object dropped: #{id}"
            rescue
              $!.print_stack_trace
            end
          end
        end
      }
    end

    # convert ruby arguments array to corresponding UMI values
    def prepare_args args
      args.map {|x|
        if x.respond_to?(:_as_umi_arg)
          x._as_umi_arg(self)
        else
          case x
            when Time
              { __type: 'unixtime', seconds: x.to_i}
            when String
              x.encoding == Encoding::BINARY ? {__type: 'binary', base64: Base64.encode64(x)} : x
            else
              x
          end
        end
      }
    end

    # Convert remote call result from UMI structures to ruby types
    def encode_result value
      case value
        when Hashie::Mash
          type = value.__type
          case type
            when 'RemoteObject';
              create_reference value
            when 'binary';
              Base64.decode64(value.base64)
            when 'unixtime';
              Time.at(value.seconds)
            else
              value
          end
        when Hashie::Array
          value.map {|x| encode_result x}
        else
          value
      end
    end

    # @raise Error if interface is closed
    def ensure_open
      raise Error, "UMI interface is closed" if @closed
    end

    EMPTY_KWARGS = {}

    # perform UMI remote call
    def call(command, *args)
      log ">> #{command}(#{args})"
      result = @endpoint.sync_call(command, *args, **EMPTY_KWARGS)
      log "<< #{result}"
      result
    rescue Farcall::RemoteError => e
      case e.remote_class
        when 'NoSuchMethodException'
          raise NoMethodError, e.message
        else
          raise
      end
    end

    def log msg
      @trace and puts "UMI #{msg}"
    end

  end

  ##
  # A reference to any Java-object that can call its methods like usual methods:
  #
  #     key = umi.instantiate "PrivateKey", 2048 # this returns Ref
  #     address = key.getPublicKey().getShortAddress().toString()
  #
  # Notice that all methods called after +key+ are java methods of +PrivateKey+, +PublicKey+ and +KeyAddress+
  # Java classes, whose references are created on-the-fly automatically (and will be reclaimed by GC on both
  # ends soon).
  #
  # == Instances are uniqie
  #
  # What means, if some calls will return the same Java object instance, it will be returned as the same {Ref}
  # instance.
  #
  # == Reference equality (== and !=)
  #
  # References are equal if they refer the same objects OR their are +equals+ - the java.equals() is called
  # to compare different referenced objects. Therefore, to compare two references use:
  #
  # - `==`: returns true if referencs are to the same object or different objects that where left.equals(right)
  #         returns true.
  # - `!=`: same as !(left == right)
  # - `===`: thest that references refer to exactly same object instance. E.g. it is possible that
  #          `left == right && !()left === right) - different objects which `equals()`.
  #
  # Reference lifespan
  #
  # Each {Ref} has an allocated object in the remote side which is retained until explicetly freed by the proper
  # UMI call. {Ref} class rakes care of it: when the ruby +Ref+ instance is garbage collected, its remote counterpart
  # will shortly receive drop command preventing memory leakage.
  #
  # == Arguments
  #
  # you can use basic ruby objects as arguments: strings, numbers, arrays, hashes, and {Ref} instances too. Note
  # that:
  #
  # - binary string (Encoding::Binary) are converted to byte[] iin Java side
  # - utf8 strings are passed as strings.
  #
  # == Return value
  #
  # Will be deep-converted to corresponding ruby objects: hashes, arrays, sets, numbers, strings and {Ref} instances
  # as need. It is, generally, inverse of converting arguments covered above.
  #
  class Ref
    # Create new reference. Do not call it directly: the {UMI} instance will do it in a correct order.
    # @param [UMI] umi instance to bind to
    # @param [Hash] ref UMI reference structure
    def initialize(umi, ref)
      @umi, @ref = umi, ref
      @id = ref.id
    end

    # @return [UMI] interface that this reference is bound to (and created by)
    def _umi
      @umi
    end

    # @return [Object] remote object id. Could be of any type actually.
    def _remote_id
      @id
    end

    # name of the remote class (provided by remote)
    def _remote_class_name
      @ref.className
    end

    # Internal use only. Allow processing remote commands as local calls
    def respond_to_missing?(method_name, include_private = false)
      method_name[0] == '_' || LOCAL_METHODS.include?(method_name) ? super : true
    end

    # Internal use only. Call remote method as needed. This is where all the magick comes from: it call remote method instead of the
    # local one, exactly like it is local.
    def method_missing(method_name, *args, &block)
      if method_name[0] == '_'
        super
      else
        @umi.invoke self, method_name, *args
      end
    end

    # Internal use only. This allow Ref instance to be an argument to the remote call. Convert it to proper UMI structure.
    def _as_umi_arg(umi)
      umi == @umi or raise InterchangeError
      @ref
    end

    # short data label for instance
    def inspect
      "<UMI:Ref:#{@umi.__id__}:#{@ref.className}:#{@id}>"
    end

    # Checks that references are euqal: either both point to the same remote object or respective remote objects
    # are reported equals by the remote +equals()+ call.
    def ==(other)
      (other.is_a?(Ref) || other.is_a?(RemoteAdapter)) && other._umi == @umi &&
          (other._remote_id == @id || other.equals(self))
    end

    # Equal references. Both point to the same remote object. Note that it should never happen with {UMI} class
    # as it do cache non-recycled references and share them between calls.
    def ===(other)
      other.is_a?(Ref) && other._umi == @umi && other._remote_id == @id
    end

    private

    LOCAL_METHODS = Set.new(%i[i_respond_to_everything_so_im_not_really_a_matcher to_hash to_ary description])
  end

  # Service uses this class to contruct {RemoteAdapter} pointing to the existing remote object instead
  # of instantiating new one.
  #
  class ReferenceCreationData
    # reference to create proxy for
    # @return [Ref]
    attr :ref

    # we need to wrap this ref
    # @param [Ref] ref to wrap in {RemoteAdapter}
    def initialize ref
      @ref = ref
    end
  end

end
