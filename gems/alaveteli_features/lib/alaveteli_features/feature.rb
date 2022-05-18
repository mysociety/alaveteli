module AlaveteliFeatures
  ##
  # A basic feature class
  #
  class Feature
    attr_reader :key, :label

    def initialize(key:, label: nil)
      @key = key
      @label = label || key
    end

    def to_sym
      key.to_sym
    end
  end
end
