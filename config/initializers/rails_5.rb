module Rails
  def self.version5?
    Gem::Version.new(5) <= gem_version && gem_version < Gem::Version.new(6)
  end

  def self.gem_version
    Gem::Version.new(version)
  end
  private_class_method :gem_version
end
