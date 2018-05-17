# -*- encoding : utf-8 -*-

module AlaveteliRateLimiter
  class Window
    VALID_UNITS = %w(
      second
      minute
      hour
      day
      week
      month
      year
    ).map(&:to_sym).freeze

    def self.from_hash(hash)
      new(hash.fetch(:value), hash.fetch(:unit))
    end

    attr_reader :value
    attr_reader :unit

    # Create a new Window
    #
    # value - Number of unit that makes up the Window
    # unit  - One of VALID_UNITS that define the Window
    #
    # Example
    #
    #   # A 1 hour period
    #   new(1, :hour)
    #
    #   # A 3 day period
    #   new(3, :day)
    #
    # Returns a Window
    def initialize(value, unit)
      @value = Integer(value)
      @unit = validate_unit(unit)
    end

    # Public: Is the event in the Window?
    #
    # event - a Time-like record
    #
    # Returns a Boolean
    def include?(event)
      event > cutoff
    end

    # Public: The end of the Window relative to now
    #
    # Returns an ActiveSupport::TimeWithZone
    def cutoff
      value.send(unit).ago
    end

    def ==(other)
      value == other.value &&
        unit == other.unit
    end

    private

    def validate_unit(unit)
      msg = "Invalid unit :#{ unit } - must be one of #{ VALID_UNITS }"
      raise ArgumentError, msg unless VALID_UNITS.include?(unit)
      unit
    end
  end
end
