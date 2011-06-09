=begin
  rmsgfmt.rb - Generate a .mo

  Copyright (C) 2003-2009 Masao Mutoh

  You may redistribute it and/or modify it under the same
  license terms as Ruby or LGPL.
=end

require 'optparse'
require 'fileutils'
require 'gettext'
require 'gettext/tools/poparser'
require 'rbconfig'

module GetText

  module RMsgfmt  #:nodoc:
    extend GetText
    extend self

    bindtextdomain "rgettext"

    def run(targetfile = nil, output_path = nil) # :nodoc:
      unless targetfile
	targetfile, output_path = check_options
      end
      unless targetfile
	raise ArgumentError, _("no input files")
      end
      unless output_path
	output_path = "messages.mo"
      end

      parser = PoParser.new
      data = MOFile.new

      parser.parse_file(targetfile, data)
      data.save_to_file(output_path)
    end

    def check_options # :nodoc:
      output = nil

      opts = OptionParser.new
      opts.banner = _("Usage: %s input.po [-o output.mo]" % $0)
      opts.separator("")
      opts.separator(_("Generate binary message catalog from textual translation description."))
      opts.separator("")
      opts.separator(_("Specific options:"))

      opts.on("-o", "--output=FILE", _("write output to specified file")) do |out|
        output = out
      end

      opts.on_tail("--version", _("display version information and exit")) do
        puts "#{$0} #{GetText::VERSION}"
        puts "#{File.join(Config::CONFIG["bindir"], Config::CONFIG["RUBY_INSTALL_NAME"])} #{RUBY_VERSION} (#{RUBY_RELEASE_DATE}) [#{RUBY_PLATFORM}]"
        exit
      end
      opts.parse!(ARGV)

      if ARGV.size == 0
        puts opts.help
        exit 1
      end

      [ARGV[0], output]
    end
  end
  
  # Creates a mo-file from a targetfile(po-file), then output the result to out. 
  # If no parameter is set, it behaves same as command line tools(rmsgfmt).
  # * targetfile: An Array of po-files or nil.
  # * output_path: output path.
  # * Returns: the MOFile object.
  def rmsgfmt(targetfile = nil, output_path = nil)
    RMsgfmt.run(targetfile, output_path)
  end
end

if $0 == __FILE__ then
  GetText.rmsgfmt
end
