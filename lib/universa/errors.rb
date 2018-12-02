module Universa

  # Basic error reported by Universa library.
  class Error < IOError
  end

  # Genegal error with universa network
  class NetworkError < Error
  end

  # references from different {UMI} instances are mixed together
  class InterchangeError < Error
    # create instance optionally overriding message
    def initialize(text = "objects can't be interchanged between different UMI interfaces")
      super(text)
    end
  end

  class StoreError < Error;
  end

  class NotFoundError < StoreError
  end

  class IllegalStateError < StoreError

  end

  # Easy print stack trace refinement
  refine Exception do

    # syntax sugar: print exception class, message and stack trace (with line feeds) to
    # the stderr.
    def print_stack_trace
      STDERR.puts "Error (#{self.class.name}): #{self}"
      STDERR.puts self.backtrace.join("\n")
    end
  end
end