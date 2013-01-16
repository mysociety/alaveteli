# Taken from
# https://rails.lighthouseapp.com/projects/8994/tickets/2946
# http://github.com/rails/rails/commit/6f97ad07ded847f29159baf71050c63f04282170

# Otherwise times get stored wrong during British Summer Time

# Hopefully fixed in later Rails. There is a test in spec/lib/timezone_fixes_spec.rb

# This fix is applied in Rails 3.x. So, should be possible to remove this then!

# Monkeypatch!
module ActiveRecord
  module ConnectionAdapters # :nodoc:
    module Quoting
       def quoted_date(value)
        if value.acts_like?(:time)
          zone_conversion_method = ActiveRecord::Base.default_timezone == :utc ? :getutc : :getlocal
          value.respond_to?(zone_conversion_method) ? value.send(zone_conversion_method) : value
        else
          value
        end.to_s(:db)
       end
    end
  end
end

