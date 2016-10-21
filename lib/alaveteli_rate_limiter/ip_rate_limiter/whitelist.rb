# -*- encoding : utf-8 -*-
require 'ipaddr'
require 'set'

module AlaveteliRateLimiter
  class IPRateLimiter
    class Whitelist
      attr_reader :addresses

      def initialize(list = [])
        @addresses = Set.new(Array(list)).map { |item| IPAddr.new(item.to_s) }
      end

      def include?(addr)
        addresses.include?(IPAddr.new(addr.to_s))
      end

      def ==(other)
        addresses == other.addresses
      end
    end
  end
end
