##
# Detect and warn when Xapian database is accessed during tests.
#
# Prepends hooks on ActsAsXapian.readable_init and .writable_init to
# emit warnings with a backtrace snippet, making it easy to find specs
# that depend on a live Xapian index.
#
module XapianIsolation
  module Warning
    def readable_init
      XapianIsolation.warn_xapian_access('readable_init')
      super
    end

    def writable_init(_suffix = "")
      XapianIsolation.warn_xapian_access('writable_init')
      super
    end
  end

  def self.warn_xapian_access(method)
    example = RSpec.current_example
    return if example&.metadata&.dig(:xapian)

    warn "[XAPIAN] #{method} called during test"
  end
end

ActsAsXapian.singleton_class.prepend(XapianIsolation::Warning)
