$:.unshift "./lib"

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/packagetask'
require 'rake/gempackagetask'

require 'locale/version'

#desc "Default Task"
#task :default => [ :test ]

PKG_VERSION = Locale::VERSION

# Run the unit tests
task :test do 
  Dir.glob("test/test_*.rb").each do |v|
    ruby "-Ilib #{v}"
  end
end

Rake::RDocTask.new { |rdoc|
  begin
    allison = `allison --path`.chop
  rescue Exception
    allison = ""
  end
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = "Ruby-Locale library"
  rdoc.options << "--line-numbers" << "--inline-source" <<
      "--accessor" << "cattr_accessor=object" << "--charset" << "utf-8"
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('ChangeLog')
  rdoc.rdoc_files.add('lib')
  rdoc.template = allison if allison.size > 0
}

desc "Create gem and tar.gz"
spec = Gem::Specification.new do |s|
  s.name = 'locale'
  s.version = PKG_VERSION
  s.summary = 'Ruby-Locale is the pure ruby library which provides basic APIs for localization.'
  s.author = 'Masao Mutoh'
  s.email = 'mutomasa at gmail.com'
  s.homepage = 'http://locale.rubyforge.org/'
  s.rubyforge_project = "locale"
  s.files = FileList['**/*'].to_a.select{|v| v !~ /pkg|CVS/}
  s.require_path = 'lib'
  s.bindir = 'bin'
  s.has_rdoc = true
  s.description = <<-EOF
    Ruby-Locale is the pure ruby library which provides basic APIs for localization.
  EOF
end

unless RUBY_PLATFORM =~ /win32/
  Rake::PackageTask.new("ruby-locale", PKG_VERSION) do |o|
    o.package_files = FileList['**/*'].to_a.select{|v| v !~ /pkg|CVS/}
    o.need_tar_gz = true
    o.need_zip = false
  end
end

Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar_gz = false
  p.need_zip = false
end

desc "Publish the release files to RubyForge."
task :release => [ :package ] do
  require 'rubyforge'

  rubyforge = RubyForge.new
  rubyforge.configure
  rubyforge.login
  rubyforge.add_release("locale", "locale",
                        PKG_VERSION,
                        "pkg/locale-#{PKG_VERSION}.gem",
                        "pkg/ruby-locale-#{PKG_VERSION}.tar.gz")
end
