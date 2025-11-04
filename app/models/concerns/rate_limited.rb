# Ability to set and check the rate at which records are created.
#
# Custom limits can be set per record type:
#
# rate_limited 5 => 30.minutes, 10 => 2.hours
#
# Read this as: "A maximum of N (records) every X (time)"
module RateLimited
  extend ActiveSupport::Concern

  DEFAULT_CREATION_RATE_LIMITS = {
    1 => 2.seconds,
    2 => 5.minutes,
    4 => 30.minutes,
    6 => 1.hour
  }.freeze

  included do
    class << self
      def rate_limited(limits = nil)
        self.creation_rate_limits = limits if limits
      end
    end

    cattr_accessor :creation_rate_limits,
                   instance_accessor: false,
                   default: DEFAULT_CREATION_RATE_LIMITS
  end

  class_methods do
    def exceeded_creation_rate?(records)
      records = records.reorder(created_at: :desc)

      creation_rate_limits.any? do |limit, duration|
        records.where(created_at: duration.ago..).size >= limit
      end
    end
  end
end
