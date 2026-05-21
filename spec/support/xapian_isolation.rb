##
# Prevent Xapian database access during tests.
#
# Prepends hooks on ActsAsXapian.readable_init and .writable_init that
# raise when called from a spec not tagged with :xapian. This ensures
# new specs cannot accidentally depend on a live Xapian database.
#
module XapianIsolation
  XapianAccessError = Class.new(Exception) # rubocop:disable Lint/InheritException

  module Guard
    def readable_init
      XapianIsolation.guard_xapian_access!('readable_init')
      super
    end

    def writable_init(_suffix = "")
      XapianIsolation.guard_xapian_access!('writable_init')
      super
    end
  end

  def self.guard_xapian_access!(method)
    example = RSpec.current_example
    return if example&.metadata&.dig(:xapian)

    raise XapianAccessError,
          "#{method} called during test without :xapian tag"
  end
end

ActsAsXapian.singleton_class.prepend(XapianIsolation::Guard)
