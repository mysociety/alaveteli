# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{xapian-full}
  s.version = "1.2.9"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Tom Adams", "Rich Lane", "Seb Bacon"]
  s.date = %q{2009-12-21}
  s.description = %q{Xapian bindings for Ruby without dependency on system Xapian library}
  s.email = %q{rlane@club.cc.cmu.edu}
  s.extensions = ["Rakefile"]
  s.files = [
     "lib/xapian.rb",
     "Rakefile",
     "xapian-bindings-1.2.9.tar.gz",
     "xapian-core-1.2.9.tar.gz",
     "xapian-full.gemspec",
  ]
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.3}
  s.summary = %q{xapian-core + Ruby xapian-bindings}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
