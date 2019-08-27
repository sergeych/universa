module Universa

  # Experimental!
  #
  # Memoizable lazy pattern. A value that is calculated only once and onlywhen first time {get} is called.
  # LazyValue is thread-safe and calculates its value exactly once.
  class LazyValue

    # initialize lazy value with an optional initializer block. If no initializer block is given, then
    # {get} call must provide one.
    def initialize(&block)
      @value = nil
      @ready = false
      @initializer = block
      @mutex = Mutex.new
    end

    # Get the value, calculating it using initializer block specified in the params or at creation time
    # if no block is provided
    def get(&block)
      @mutex.synchronize {
        if @ready
          @value
        else
          @initializer = block if block
          @value = @initializer.call
          @ready = true
          @value
        end
      }
    end

    # causes value to be recalculated on next call to {get}
    def clear
      @ready = false
    end
  end

  # Add class-level lazy declaration like:
  #
  #     class Test
  #         lazy(:foo) {
  #           puts "foo calculated"
  #           "bar"
  #         }
  #
  #     t = Test.new
  #     t.foo # "foo calculated" -> "bar"
  #     t.foo #=> "bar"
  #
  module Lazy

    # prevent from creation multiple instances of LazyValue's
    @@lazy_creation_mutex = Mutex.new

    def Lazy.included(other)
      # implement class-level lazy instance var definition
      def other.lazy(name, &block)
        define_method(name.to_sym) {
          x = @@lazy_creation_mutex.synchronize {
            cache_name = :"@__#{name}__cache"
            if !(x = instance_variable_get(cache_name))
              x = LazyValue.new { instance_exec &block }
              instance_variable_set(cache_name, x)
            end
            x
          }
          x.get
        }
      end
    end
  end
end