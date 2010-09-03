
module Interlock
  #
  # A stub class so that does not cache, for use in the test environment and the console
  # when the MemoryStore is not available.
  #
  class PassThroughStore
    
    # Do nothing.
    def nothing(*args)
      nil
    end
    
    alias :read :nothing
    alias :write :nothing
    alias :delete :nothing

  end
end