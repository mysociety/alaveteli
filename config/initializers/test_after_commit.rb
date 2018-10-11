if Rails.version5?

  class TestAfterCommit
    def self.with_commits(*_args, &block)
      block.call
    end

    def self.enabled=(_arg); end
  end

end
