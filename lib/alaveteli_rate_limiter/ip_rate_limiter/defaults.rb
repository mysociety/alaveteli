# -*- encoding : utf-8 -*-

module AlaveteliRateLimiter
  class IPRateLimiter
    class Defaults
      EVENT_RULES = {
        :signup => { :count => 3, :window => { :value => 1, :unit => :hour } },
        :request => { :count => 3, :window => { :value => 1, :unit => :hour } },
        :comment => { :count => 20, :window => { :value => 1, :unit => :hour } }
      }

      attr_accessor :whitelist
      attr_accessor :event_rules

      def initialize(opts = {})
        @whitelist = opts[:whitelist] || Whitelist.new
        @event_rules = opts[:event_rules] || EVENT_RULES
      end

      def ==(other)
        %w(whitelist event_rules).
          all? { |attr| send(attr) == other.send(attr) }
      end
    end
  end
end
