# -*- encoding : utf-8 -*-
module AlaveteliRateLimiter
  # Class to encapsulate how many times an event can happen in a given Window.
  class Rule
    # Public: Create a new Rule from a Hash
    #
    # hash - Hash of attributes
    #        :name   - Symbol name of the event
    #        :count  - How many times the event can happen in the window
    #        :window - Options to construct a window
    #          :value - Number of :window_unit that makes up the window
    #          :unit  - One of VALID_UNITS that define the window
    #
    # Example
    #
    #   # Rule that allows an event to happen 10 times in a 1 hour period
    #   new(:name => :test,
    #       :count => 10,
    #       :window => { :value => 1, :unit => :hour })
    #
    # Returns a Rule
    def self.from_hash(hash)
      new(hash.fetch(:name),
          hash.fetch(:count),
          Window.from_hash(hash.fetch(:window)))
    end

    attr_reader :name
    attr_reader :count
    attr_reader :window

    def initialize(name, count, window)
      @name = name.to_sym
      @count = Integer(count)
      @window = window
    end

    def ==(other)
      name == other.name &&
        count == other.count &&
        window == other.window
    end

    # Public: Are there more records in the Window than the Rule allows?
    #
    # records - An Array of Time-like records
    #
    # Returns a Boolean indicating whether the records given are over the limit
    def limit?(records)
      records.count { |date| window.include?(date) } > count
    end

    def records_in_window(records)
      records.select { |date| window.include?(date) }
    end
  end
end
