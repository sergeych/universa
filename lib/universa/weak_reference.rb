module Universa

  # The smarter and safer weak reference than a standard one.
  # It keeps object_id even if it is GC'd and can create a hard
  # reference when possible. Some code borrowed from
  # https://github.com/ruby-concurrency/ref.
  #
  # Note there is no +alive?+ method because it is not thread safe.
  # Use the safe approach:
  #
  #     weak = WeakReference.new(something)
  #     hard = weak.get
  #     if hard
  #        # we got safe reference in +hard+
  #     end
  #
  # or, scala/kotlin-style:
  #
  #     weak.let { |object|
  #       object.do_somethinf
  #     }
  #
  class WeakReference

    # ruby object it of the referenced object. Available also after object is recycled.
    attr :referenced_object_id

    # Create weak reference for a given object
    def initialize(object)
      @referenced_object_id = object.__id__
      @weakref = WeakRef.new(object)
    end

    # Call the block passing it hard ref to the object if it is not yet recycled
    #
    # @return what the block returned or nil
    # @yield object if it is not recycled
    def let
      if (hardref = object.get)
        yield hardref
      else
        nil
      end
    end

    # Get the strong reference unless it is already reclaimed.
    #
    # @return [Object] har reference to the source object or nil
    def get
      @weakref.__getobj__
    rescue => e
      # Jruby implementation uses RefError while MRI uses WeakRef::RefError
      if (defined?(RefError) && e.is_a?(RefError)) || (defined?(::WeakRef::RefError) && e.is_a?(::WeakRef::RefError))
        nil
      else
        raise e
      end
    end
  end
end