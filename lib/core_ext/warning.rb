Warning.module_eval do
  class RaisedWarning < StandardError; end

  def self.with_raised_warnings(&block)
    alias_method :warn_original, :warn
    alias_method :warn, :raise_warning
    block.call if block_given?
  ensure
    alias_method :warn, :warn_original
  end

  def raise_warning(msg)
    raise RaisedWarning, msg
  end
end
