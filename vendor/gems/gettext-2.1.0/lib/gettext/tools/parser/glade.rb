=begin
  parser/glade.rb - parser for Glade-2

  Copyright (C) 2004,2005  Masao Mutoh
 
  You may redistribute it and/or modify it under the same
  license terms as Ruby or LGPL.
=end

require 'cgi'
require 'gettext'

module GetText
  module GladeParser
    extend GetText
    extend self
    
    bindtextdomain("rgettext")

    TARGET1 = /<property.*translatable="yes">(.*)/
    TARGET2 = /(.*)<\/property>/

    def parse(file, targets = []) # :nodoc: 
      lines = IO.readlines(file)
      parse_lines(file, lines, targets)
    end

    #from ary of lines.
    def parse_lines(file, lines, targets) # :nodoc:
      cnt = 0
      target = false
      line_no = 0
      val = nil
      
      loop do 
        line = lines.shift
        break unless line
        
        cnt += 1
        if TARGET1 =~ line
          line_no = cnt
          val = $1 + "\n"
          target = true
          if TARGET2 =~ $1
            val = $1
            add_target(val, file, line_no, targets)
            val = nil
            target = false
          end
        elsif target
          if TARGET2 =~ line
            val << $1
            add_target(val, file, line_no, targets)
            val = nil
            target = false
          else
            val << line
          end
        end
      end
      targets
    end

    XML_RE = /<\?xml/ 
    GLADE_RE = /glade-2.0.dtd/
 
    def target?(file) # :nodoc:
      data = IO.readlines(file)
      if XML_RE =~ data[0] and GLADE_RE =~ data[1]
	true
      else
	if File.extname(file) == '.glade'
	  raise _("`%{file}' is not glade-2.0 format.") % {:file => file}
	end
	false
      end
    end

    def add_target(val, file, line_no, targets) # :nodoc:
      return unless val.size > 0
      assoc_data = targets.assoc(val)
      val = CGI.unescapeHTML(val)
      if assoc_data 
        targets[targets.index(assoc_data)] = assoc_data << "#{file}:#{line_no}"
      else
        targets << [val.gsub(/\n/, '\n'), "#{file}:#{line_no}"]
      end
      targets
    end
  end
end

if __FILE__ == $0
  # ex) ruby glade.rb foo.glade  bar.glade
  ARGV.each do |file|
    p GetText::GladeParser.parse(file)
  end
end
