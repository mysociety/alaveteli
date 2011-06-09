#!/usr/bin/ruby
=begin
  parser/ruby.rb - parser for ruby script

  Copyright (C) 2003-2009  Masao Mutoh
  Copyright (C) 2005       speakillof
  Copyright (C) 2001,2002  Yasushi Shoji, Masao Mutoh
 
  You may redistribute it and/or modify it under the same
  license terms as Ruby or LGPL.

=end

require 'irb/ruby-lex.rb'
require 'stringio'
require 'gettext/tools/pomessage'

module GetText
  class RubyLexX < RubyLex  # :nodoc: all
    # Parser#parse resemlbes RubyLex#lex
    def parse
      until (  (tk = token).kind_of?(RubyToken::TkEND_OF_SCRIPT) && !@continue or tk.nil?  )
        s = get_readed
        if RubyToken::TkSTRING === tk
          def tk.value
            @value 
          end
          
          def tk.value=(s)
            @value = s
          end
          
          if @here_header
            s = s.sub(/\A.*?\n/, '').sub(/^.*\n\Z/, '')
          else
            begin
              s = eval(s)
            rescue Exception
              # Do nothing.
            end
          end
          
          tk.value = s
        end
        
        if $DEBUG
          if tk.is_a? TkSTRING
            $stderr.puts("#{tk}: #{tk.value}")
          elsif tk.is_a? TkIDENTIFIER
            $stderr.puts("#{tk}: #{tk.name}")
          else
            $stderr.puts(tk)
          end
        end
        
        yield tk
      end
      return nil
    end

    # Original parser does not keep the content of the comments,
    # so monkey patching this with new token type and extended
    # identify_comment implementation
    RubyToken.def_token :TkCOMMENT_WITH_CONTENT, TkVal

    def identify_comment
      @ltype = "#"
      get_readed # skip the hash sign itself

      while ch = getc
        if ch == "\n"
          @ltype = nil
          ungetc
          break
        end
      end
      return Token(TkCOMMENT_WITH_CONTENT, get_readed)
    end

  end

  # Extends PoMessage for RubyParser.
  # Implements a sort of state machine to assist the parser.
  module PoMessageForRubyParser
    # Supports parsing by setting attributes by and by.
    def set_current_attribute(str)
      param = @param_type[@param_number]
      raise ParseError, 'no more string parameters expected' unless param
      set_value(param, str)
    end

    def init_param
      @param_number = 0
      self
    end

    def advance_to_next_attribute
      @param_number += 1
    end    
  end
  class PoMessage
    include PoMessageForRubyParser
    alias :initialize_old :initialize
    def initialize(type)
      initialize_old(type)
      init_param
    end
  end

  module RubyParser
    extend self
    
    ID = ['gettext', '_', 'N_', 'sgettext', 's_']
    PLURAL_ID = ['ngettext', 'n_', 'Nn_', 'ns_', 'nsgettext']
    MSGCTXT_ID = ['pgettext', 'p_']
    MSGCTXT_PLURAL_ID = ['npgettext', 'np_']

    # (Since 2.1.0) the 2nd parameter is deprecated
    # (and ignored here). 
    # And You don't need to keep the pomessages as unique.

    def parse(path, deprecated = [])  # :nodoc:
      lines = IO.readlines(path)
      parse_lines(path, lines, deprecated)
    end

    def parse_lines(path, lines, deprecated = [])  # :nodoc:
      pomessages = deprecated
      file = StringIO.new(lines.join + "\n")
      rl = RubyLexX.new
      rl.set_input(file)
      rl.skip_space = true
      #rl.readed_auto_clean_up = true

      pomessage = nil
      line_no = nil
      last_comment = ''
      reset_comment = false
      rl.parse do |tk|
        begin
          case tk
          when RubyToken::TkIDENTIFIER, RubyToken::TkCONSTANT
            store_pomessage(pomessages, pomessage, path, line_no, last_comment)
            if ID.include?(tk.name)
              pomessage = PoMessage.new(:normal)
            elsif PLURAL_ID.include?(tk.name)
              pomessage = PoMessage.new(:plural)
            elsif MSGCTXT_ID.include?(tk.name)
              pomessage = PoMessage.new(:msgctxt)
            elsif MSGCTXT_PLURAL_ID.include?(tk.name)
              pomessage = PoMessage.new(:msgctxt_plural)
            else
              pomessage = nil
            end
            line_no = tk.line_no.to_s
          when RubyToken::TkSTRING
            pomessage.set_current_attribute tk.value if pomessage
          when RubyToken::TkPLUS, RubyToken::TkNL
            #do nothing
          when RubyToken::TkCOMMA
            pomessage.advance_to_next_attribute if pomessage
          else
            if store_pomessage(pomessages, pomessage, path, line_no, last_comment)
              pomessage = nil
            end
          end
        rescue
          $stderr.print "\n\nError"
          $stderr.print " parsing #{path}:#{tk.line_no}\n\t #{lines[tk.line_no - 1]}" if tk
          $stderr.print "\n #{$!.inspect} in\n"
          $stderr.print $!.backtrace.join("\n")
          $stderr.print "\n"
          exit 1
        end

        case tk 
        when RubyToken::TkCOMMENT_WITH_CONTENT
          last_comment = "" if reset_comment
          if last_comment.empty?
            # new comment from programmer to translator?
            comment1 = tk.value.lstrip
            if comment1 =~ /^TRANSLATORS\:/
              last_comment = $'
            end
          else
            last_comment += "\n" 
            last_comment += tk.value
          end
          reset_comment = false
        when RubyToken::TkNL
        else
          reset_comment = true
        end
      end
      pomessages
    end

    def target?(file)  # :nodoc:
      true # always true, as the default parser.
    end

    private
    def store_pomessage(pomessages, pomessage, file_name, line_no, last_comment) #:nodoc:
      if pomessage && pomessage.msgid
        pomessage.sources << file_name + ":" + line_no
        pomessage.add_comment(last_comment) unless last_comment.empty?
        pomessages << pomessage
        true
      else
        false
      end
    end
  end 
end

if __FILE__ == $0
  require 'pp'
  ARGV.each do |path|
    pp GetText::RubyParser.parse(path)
  end
  
  #rl = GetText::RubyLexX.new; rl.set_input(ARGF)  
  #rl.parse do |tk|
  #p tk
  #end  
end
