require 'farcall/smart_hash'
require 'concurrent'

module Universa

  # The Hashie::Mash without warnings, just copied from Farcall to not to copy it again
  class SmartHash < Farcall::SmartHash
  end

  def retry_with_timeout(max_timeout = 15, max_times = 3, &block)
    attempt = 0
    Timeout::timeout(max_timeout, &block)
  rescue
    attempt += 1
    puts "timeout: retry (#$!): #{attempt}"
    retry if attempt < max_times
    raise
  end

  module Parallel

    # The eollection-like delegate supporting parallel execution on {#each}, {#each_with_index} and {#map}.
    # Use +refine Enumerable+ to easily construct it as simple as +collection.par+. Inspired by Scala.
    class ParallelEnumerable < SimpleDelegator
      include Concurrent

      @@pool = CachedThreadPool.new

      # Enumerates in parallel all items. Like {Enumerable#each_with_index}, but requires block.
      # Blocks until all items are processed.
      #
      # @param [Proc] block to call with (object, index) parameters
      # @return self
      def each_with_index &block
        latch = CountDownLatch.new(size)
        __getobj__.each_with_index {|x, index|
          @@pool << -> {
            begin
              block.call(x, index)
            rescue
              $!.print_stack_trace
            ensure
              latch.count_down
            end
          }
        }
        latch.wait
        self
      end

      # Call the given block on each item in the collection in parallel, blocks until all items are processed
      #
      # @return self
      def each &block
        each_with_index {|x, i| block.call(x)}
      end

      # Parallel version of the {Enumerable#map}. Creates a new array containing the values returned by the block,
      # using parallel execution in threads.
      #
      # @return new array containing the values returned by the block.
      def map &block
        result = size.times.map {nil}
        each_with_index {|value, i|
          result[i] = block.call(value)
        }
        result.par
      end

      alias_method :collect, :map
    end

    # Enhance any Enumerable instance with few utilities.
    refine Enumerable do

      # Creates {ParallelEnumerable} from self.
      #
      # @return [ParallelEnumerable] over the self
      def par
        is_a?(ParallelEnumerable) ? self : ParallelEnumerable.new(self)
      end

      # Group elements by the value returned by the block. Return map where keys are one returned by the block
      # and values are arrays of elements of the given Enumerable with corresponding block.
      #
      # @param [Object] block that calculates keys to group with for each source elements.
      # @return [Hash] of grouped source elements
      def group_by(&block)
        result = {}
        each {|value|
          new_key = block.call(value)
          (result[new_key] ||= []) << value
        }
        result
      end
    end

    refine Array do

      # Creates {ParallelEnumerable} from self.
      #
      # @return [ParallelEnumerable] over the self
      def par
        is_a?(ParallelEnumerable) ? self : ParallelEnumerable.new(self)
      end

      # Group elements by the value returned by the block. Return map where keys are one returned by the block
      # and values are arrays of elements of the given Enumerable with corresponding block.
      #
      # @param [Object] block that calculates keys to group with for each source elements.
      # @return [Hash] of grouped source elements
      def group_by(&block)
        result = {}
        each {|value|
          new_key = block.call(value)
          (result[new_key] ||= []) << value
        }
        result
      end
    end

  end

end