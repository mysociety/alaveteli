module AlaveteliFeatures
  ##
  # Class to provide a better DSL to add features and groups.
  #
  # Will automatically extend the collection with module with chainable methods
  # which will filter the collection items.
  #
  # Example:
  #   features = Collection.new(Feature) #=> <Collection klass=Feature ...>
  #   features.add(:test_feature) #=> <Feature key=test_feature ...>
  #   features.all #=> [<Feature key=test_feature ...>]
  #
  # Extended method example:
  #   features.enabled?(:test_feature) #=> true/false
  #
  class Collection
    include Enumerable

    attr_reader :klass

    def initialize(klass)
      @klass = klass

      return unless klass.const_defined?(:CollectionMethods)

      extend klass::CollectionMethods
    end

    def add(key, **kargs)
      instance = klass.new(key: key, **kargs)
      all << instance
      instance
    end

    def all
      @items ||= []
    end

    def each(*_args, &block)
      return to_enum(:each) unless block_given?

      all.each(&block)
    end
  end
end
