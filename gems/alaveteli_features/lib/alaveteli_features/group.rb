module AlaveteliFeatures
  ##
  # A basic group class for a collection of features. A group can inherit from
  # another group and be tied to user roles.
  #
  class Group
    attr_reader :key, :includes, :roles

    def initialize(key:, features: [], includes: [], roles: [])
      @key = key
      @features = features
      @includes = includes
      @roles = roles

      self.features.each do |f|
        f.roles += roles
      end
    end

    def to_sym
      key.to_sym
    end

    def features
      (@features + includes.map(&:features)).flatten
    end
  end
end
