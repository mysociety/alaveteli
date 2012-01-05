if File.exist? File.join(File.dirname(__FILE__),'..','vendor','rails','railties','lib','rails','gem_dependency.rb')
  require File.join(File.dirname(__FILE__),'..','vendor','rails','railties','lib','rails','gem_dependency.rb')
else
  require 'rails/gem_dependency'
end

module Rails
  class GemDependency < Gem::Dependency
  
    # This definition of the requirement method is a patch
    if !method_defined?(:requirement)
      def requirement
        req = version_requirements
      end
    end
  
    def add_load_paths
      self.class.add_frozen_gem_path
      return if @loaded || @load_paths_added
      if framework_gem?
        @load_paths_added = @loaded = @frozen = true
        return
      end

      begin
        dep = Gem::Dependency.new(name, requirement)
        spec = Gem.source_index.find { |_,s| s.satisfies_requirement?(dep) }.last
        spec.activate           # a way that exists
      rescue
        begin 
          gem self.name, self.requirement # <  1.8 unhappy way
        # This second rescue is a patch - fall back to passing Rails::GemDependency to gem
        # for older rubygems
        rescue ArgumentError
          gem self
        end
      end

      @spec = Gem.loaded_specs[name]
      @frozen = @spec.loaded_from.include?(self.class.unpacked_path) if @spec
      @load_paths_added = true
    rescue Gem::LoadError
    end
  end
  
end
