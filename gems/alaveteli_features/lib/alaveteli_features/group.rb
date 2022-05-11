module AlaveteliFeatures
  ##
  # A basic group class for a collection of features. A group can inherit from
  # another group and be tied to user roles.
  #
  class Group
    attr_reader :key, :includes

    def initialize(key:, features: [], includes: [])
      @key = key
      @features = features
      @includes = includes
    end

    def to_sym
      key.to_sym
    end

    def features
      (@features + includes.map(&:features)).flatten
    end
  end
end
