require 'rake/rdoctask'
require 'rake/testtask'
require 'rake/packagetask'
require 'rake/gempackagetask'

require 'rbconfig'
require 'fileutils'

$:.unshift 'lib'

require 'mapi/msg'

PKG_NAME = 'ruby-msg'
PKG_VERSION = Mapi::VERSION

task :default => [:test]

Rake::TestTask.new(:test) do |t|
	t.test_files = FileList["test/test_*.rb"] - ['test/test_pst.rb']
	t.warning = false
	t.verbose = true
end

begin
	require 'rcov/rcovtask'
	# NOTE: this will not do anything until you add some tests
	desc "Create a cross-referenced code coverage report"
	Rcov::RcovTask.new do |t|
		t.test_files = FileList['test/test*.rb']
		t.ruby_opts << "-Ilib" # in order to use this rcov
		t.rcov_opts << "--xrefs"  # comment to disable cross-references
		t.rcov_opts << "--exclude /usr/local/lib/site_ruby"
		t.verbose = true
	end
rescue LoadError
	# Rcov not available
end

Rake::RDocTask.new do |t|
	t.rdoc_dir = 'doc'
	t.title    = "#{PKG_NAME} documentation"
	t.options += %w[--main README --line-numbers --inline-source --tab-width 2]
	t.rdoc_files.include 'lib/**/*.rb'
	t.rdoc_files.include 'README'
end

spec = Gem::Specification.new do |s|
	s.name        = PKG_NAME
	s.version     = PKG_VERSION
	s.summary     = %q{Ruby Msg library.}
	s.description = %q{A library for reading and converting Outlook msg and pst files (mapi message stores).}
	s.authors     = ["Charles Lowe"]
	s.email       = %q{aquasync@gmail.com}
	s.homepage    = %q{http://code.google.com/p/ruby-msg}
	s.rubyforge_project = %q{ruby-msg}

	s.executables = ['mapitool']
	s.files       = FileList['data/*.yaml', 'Rakefile', 'README', 'FIXES']
	s.files      += FileList['lib/**/*.rb', 'test/test_*.rb', 'bin/*']
	
	s.has_rdoc    = true
	s.extra_rdoc_files = ['README']
	s.rdoc_options += ['--main', 'README',
					   '--title', "#{PKG_NAME} documentation",
					   '--tab-width', '2']

	s.add_dependency 'ruby-ole', '>=1.2.8'
	s.add_dependency 'vpim', '>=0.360'
end

Rake::GemPackageTask.new(spec) do |p|
	p.gem_spec = spec
	p.need_tar = false #true
	p.need_zip = false
	p.package_dir = 'build'
end

