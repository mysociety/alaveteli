# -*- encoding : utf-8 -*-
module AlaveteliRateLimiter
  # A generic rate limiter that records counts of actions from a given ID in to
  # a Backend, and then uses a Rule to calculate if the frequency of the actions
  # exceeds the limit set by the Rule.
  class RateLimiter
    attr_reader :rule
    attr_reader :backend

    def initialize(rule, opts = {})
      @rule = rule
      path =
        Pathname.new(Rails.root + "tmp/#{ @rule.name }_rate_limiter.pstore")
      @backend = opts[:backend] || Backends::PStoreDatabase.new(path: path)
    end

    def records(id)
      backend.get(id.to_s)
    end

    def record(id)
      backend.record(id.to_s)
    end

    def record!(id)
      id = id.to_s
      purged = rule.records_in_window(records(id))
      backend.set(id, purged)
      record(id)
    end

    def limit?(id)
      rule.limit?(records(id.to_s))
    end
  end
end
