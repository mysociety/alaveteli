class MockCollectionObject # :nodoc:
  attr_reader :key

  def initialize(key:)
    @key = key
  end

  module CollectionMethods # :nodoc:
    attr_reader :actor

    def with_actor(actor)
      @actor = actor
      self
    end
  end
end
