#! /usr/bin/env ruby
=begin
  rgettext.rb - Generate a .pot file.

  Copyright (C) 2003-2009  Masao Mutoh
  Copyright (C) 2001,2002  Yasushi Shoji, Masao Mutoh
 
      Yasushi Shoji   <yashi at atmark-techno.com>
      Masao Mutoh     <mutomasa at gmail.com>
 
  You may redistribute it and/or modify it under the same
  license terms as Ruby or LGPL.
=end

require 'optparse'
require 'gettext'
require 'rbconfig'

module GetText

  module RGetText #:nodoc:
    extend GetText

    bindtextdomain("rgettext")

    # constant values
    VERSION = GetText::VERSION
 
    @ex_parsers = []
    [
      ["glade.rb", "GladeParser"],
      ["erb.rb", "ErbParser"],
#      ["ripper.rb", "RipperParser"],
      ["ruby.rb", "RubyParser"] # Default parser.
    ].each do |f, klass|
      begin
        require "gettext/tools/parser/#{f}"
        @ex_parsers << GetText.const_get(klass)
      rescue
        $stderr.puts _("'%{klass}' is ignored.") % {:klass => klass}
        $stderr.puts $! if $DEBUG
      end
    end

    module_function

    # Add an option parser
    # the option parser module requires to have target?(file) and parser(file, ary) method.
    # 
    #  require 'gettext/tools/rgettext'
    #  module FooParser
    #    module_function
    #    def target?(file)
    #      File.extname(file) == '.foo'  # *.foo file only.
    #    end
    #    def parse(file, ary)
    #      :
    #      return ary # [["msgid1", "foo.rb:200"], ["msgid2", "bar.rb:300", "baz.rb:400"], ...]
    #    end
    #  end
    #  
    #  GetText::RGetText.add_parser(FooParser)
    def add_parser(klass)
      @ex_parsers.insert(0, klass)
    end

    def generate_pot_header # :nodoc:
      time = Time.now.strftime("%Y-%m-%d %H:%M")
      off = Time.now.utc_offset
      sign = off <= 0 ? '-' : '+'
      time += sprintf('%s%02d%02d', sign, *(off.abs / 60).divmod(60))

      <<TITLE
# SOME DESCRIPTIVE TITLE.
# Copyright (C) YEAR THE PACKAGE'S COPYRIGHT HOLDER
# This file is distributed under the same license as the PACKAGE package.
# FIRST AUTHOR <EMAIL@ADDRESS>, YEAR.
#
#, fuzzy
msgid ""
msgstr ""
"Project-Id-Version: PACKAGE VERSION\\n"
"POT-Creation-Date: #{time}\\n"
"PO-Revision-Date: #{time}\\n"
"Last-Translator: FULL NAME <EMAIL@ADDRESS>\\n"
"Language-Team: LANGUAGE <LL@li.org>\\n"
"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=UTF-8\\n"
"Content-Transfer-Encoding: 8bit\\n"
"Plural-Forms: nplurals=INTEGER; plural=EXPRESSION;\\n"
TITLE
    end

    def generate_pot(paths) # :nodoc:
      pomessages = parse(paths)
      str = ""
      pomessages.each do |target|
        str << target.to_po_str
      end
      str
    end

    def parse(paths) # :nodoc:
      pomessages = []
      paths.each do |path|
        begin
          @ex_parsers.each do |klass|
            if klass.target?(path)
              if klass.method(:parse).arity == 1
                targets = klass.parse(path)
              else
                # For backward compatibility.
                targets = klass.parse(path, [])
              end

              targets.each{|pomessage|
                if pomessage.kind_of? Array
                  pomessage = PoMessage.new_from_ary(pomessage)
                end

                # Save the previous target.
                existing = pomessages.find_index {|t| t == pomessage}
                if existing
                  pomessage = pomessages[existing].merge(pomessage)
                  pomessages[existing] = pomessage
                else
                  pomessages << pomessage
                end
              }
              break
            end
          end
        rescue
          puts _("Error parsing %{path}") % {:path => path}
          raise
        end
      end
      pomessages
    end

    def check_options # :nodoc:
      output = STDOUT

      opts = OptionParser.new
      opts.banner = _("Usage: %s input.rb [-r parser.rb] [-o output.pot]") % $0
      opts.separator("")
      opts.separator(_("Extract translatable strings from given input files."))
      opts.separator("")
      opts.separator(_("Specific options:"))

      opts.on("-o", "--output=FILE", _("write output to specified file")) do |out|
        unless FileTest.exist? out
          output = File.new(File.expand_path(out), "w+")
        else
          $stderr.puts(_("File '%s' already exists.") % out)
          exit 1
        end
      end

      opts.on("-r", "--require=library", _("require the library before executing rgettext")) do |out|
        require out
      end

      opts.on("-d", "--debug", _("run in debugging mode")) do
        $DEBUG = true
      end

      opts.on_tail("--version", _("display version information and exit")) do
        puts "#{$0} #{VERSION}"
        puts "#{File.join(Config::CONFIG["bindir"], Config::CONFIG["RUBY_INSTALL_NAME"])} #{RUBY_VERSION} (#{RUBY_RELEASE_DATE}) [#{RUBY_PLATFORM}]"
        exit
      end

      opts.parse!(ARGV)

      if ARGV.size == 0
        puts opts.help
        exit 1
      end

      [ARGV, output]
    end

    def run(paths = nil, out = STDOUT)  # :nodoc:
      if paths.is_a? String
        paths = [paths]
      elsif ! paths
        paths, out = check_options
      end

      if paths.size == 0
        raise ArgumentError, _("no input files")
      end

      if out.is_a? String
        File.open(File.expand_path(out), "w+") do |file|
          file.puts generate_pot_header
          file.puts generate_pot(paths)
        end
      else
        out.puts generate_pot_header
        out.puts generate_pot(paths)
      end
      self
    end
  end
  extend self
  # Creates a po-file from targetfiles(ruby-script-files, .rhtml files, glade-2 XML files), 
  # then output the result to out. If no parameter is set, it behaves same as command line tools(rgettet). 
  #
  # This function is a part of GetText.create_pofiles.
  # Usually you don't need to call this function directly.
  #
  # * paths: An Array of po-file paths or nil.
  # * out: output IO or output path.
  # * Returns: self
  def rgettext(paths = nil, out = STDOUT)
    RGetText.run(paths, out)
    self
  end
end

if $0 == __FILE__
  GetText.rgettext
#  GetText.rgettext($0, "tmp.txt")
end
