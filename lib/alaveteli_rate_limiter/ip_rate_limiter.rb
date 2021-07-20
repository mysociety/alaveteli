Dir[File.dirname(__FILE__) + '/ip_rate_limiter/*.rb'].each do |file|
  require file
end

module AlaveteliRateLimiter
  class IPRateLimiter
    def self.defaults
      @defaults ||= Defaults.new
    end

    def self.set_defaults
      @defaults ||= Defaults.new
      yield(defaults)
    end

    # Public: Resets the defaults
    def self.defaults!
      @defaults = Defaults.new
    end

    attr_reader :rule
    attr_reader :backend
    attr_reader :whitelist

    def initialize(rule, opts = {})
      @rule = find_rule(rule)
      path =
        Pathname.new(Rails.root + "tmp/#{@rule.name}_ip_rate_limiter.pstore")
      @backend = opts[:backend] || Backends::PStoreDatabase.new(:path => path)
      @whitelist = opts[:whitelist] || self.class.defaults.whitelist
    end

    def records(ip)
      backend.get(clean_ip(ip).to_s)
    end

    def record(ip)
      backend.record(clean_ip(ip).to_s)
    end

    def record!(ip)
      ip = clean_ip(ip).to_s
      purged = rule.records_in_window(records(ip))
      backend.set(ip, purged)
      record(ip)
    end

    def limit?(ip)
      ip = clean_ip(ip)
      return false if whitelist.include?(ip)
      rule.limit?(records(ip.to_s))
    end

    private

    def clean_ip(ip)
      IPAddr.new(ip.to_s.strip.chomp)
    end

    def find_rule(rule)
      case rule
      when Symbol
        rules = self.class.defaults.event_rules.fetch(rule)
        Rule.from_hash(rules.merge(:name => rule))
      when Rule
        rule
      else
        raise ArgumentError, "Invalid rule: #{rule}"
      end
    end
  end
end
