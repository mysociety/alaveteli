=begin
  rmsgmerge.rb - Merge old .po to new .po

  Copyright (C) 2005-2009 Masao Mutoh
  Copyright (C) 2005,2006 speakillof

  You may redistribute it and/or modify it under the same
  license terms as Ruby or LGPL.
=end

require 'optparse'
require 'gettext'
require 'gettext/tools/poparser'
require 'rbconfig'

module GetText
    
  module RMsgMerge
    
    class PoData  #:nodoc:  
      
      attr_reader :msgids
      
      def initialize
        @msgid2msgstr = {}
        @msgid2comment = {}
        @msgids = []
      end
      
      def set_comment(msgid_or_sym, comment)
        @msgid2comment[msgid_or_sym] = comment      
      end
      
      def msgstr(msgid)
        @msgid2msgstr[msgid]
      end
      
      def comment(msgid)
        @msgid2comment[msgid]
      end
      
      def [](msgid)
        @msgid2msgstr[msgid]
      end
      
      def []=(msgid, msgstr)
        # Retain the order
        unless @msgid2msgstr[msgid]
          @msgids << msgid
        end
        
        @msgid2msgstr[msgid] = msgstr
      end
      
      def each_msgid
        arr = @msgids.delete_if{|i| Symbol === i or i == ''}
        arr.each do |i|
          yield i
        end
      end
      
      def msgid?(msgid)
        !(Symbol === msgid) and  @msgid2msgstr[msgid] and (msgid != '')
      end
      
      # Is it necessary to implement this method?
      def search_msgid_fuzzy(msgid, used_msgids)
        nil
      end
      
      def nplural
        unless @msgid2msgstr['']
          return 0
        else
          if /\s*nplural\s*=\s*(\d+)/ =~ @msgid2msgstr['']
            return $1.to_i
          else
            return 0
          end
          
        end
      end
      
      def generate_po
        str = ''
        str << generate_po_header
        
        self.each_msgid do |id|
          str << self.generate_po_entry(id)          
        end
        
        str << @msgid2comment[:last]        
        str        
      end
      
      def generate_po_header
        str = ""
        
        str << @msgid2comment[''].strip << "\n"
        str << 'msgid ""'  << "\n"                
        str << 'msgstr ""' << "\n"
        msgstr = @msgid2msgstr[''].gsub(/"/, '\"').gsub(/\r/, '')
        msgstr = msgstr.gsub(/^(.*)$/, '"\1\n"')
        str << msgstr
        str << "\n"
        
        str
      end
      
      def generate_po_entry(msgid)
        str = ""
        str << @msgid2comment[msgid]
        if str[-1] != "\n"[0]
          str << "\n"
        end
        
        id = msgid.gsub(/"/, '\"').gsub(/\r/, '')
        msgstr = @msgid2msgstr[msgid].gsub(/"/, '\"').gsub(/\r/, '')

        if id.include?("\000")
          ids = id.split(/\000/)          
          str << "msgid " << __conv(ids[0]) << "\n"
          ids[1..-1].each do |single_id|
            str << "msgid_plural " << __conv(single_id) << "\n"
          end
          
          msgstr.split("\000").each_with_index do |m, n|
            str << "msgstr[#{n}] " << __conv(m) << "\n"
          end
        else
          str << "msgid "  << __conv(id) << "\n"
          str << "msgstr " << __conv(msgstr) << "\n"
        end
        
        str << "\n"
        str
      end
      
      def __conv(str)
        s = ''

        if str.count("\n") > 1
          s << '""' << "\n"
          s << str.gsub(/^(.*)$/, '"\1\n"')
        else
          s << '"' << str.sub("\n", "\\n") << '"'
        end
        
        s.rstrip
      end
      
    end
    
    class Merger #:nodoc:
      
      # From GNU gettext source.
      # 
      # Merge the reference with the definition: take the #. and
      #	#: comments from the reference, take the # comments from
	  # the definition, take the msgstr from the definition.  Add
	  # this merged entry to the output message list.      
      DOT_COMMENT_RE = /\A#\./
      SEMICOLON_COMMENT_RE = /\A#\:/
      FUZZY_RE = /\A#\,/
      NOT_SPECIAL_COMMENT_RE = /\A#([^:.,]|\z)/
      
      CRLF_RE = /\r?\n/
      POT_DATE_EXTRACT_RE = /POT-Creation-Date:\s*(.*)?\s*$/
      POT_DATE_RE = /POT-Creation-Date:.*?$/
      
      def merge(definition, reference)
        # deep copy
        result = Marshal.load( Marshal.dump(reference) )        
        
        used = []        
        merge_header(result, definition)

        result.each_msgid do |msgid|
          if definition.msgid?(msgid)
            used << msgid
            merge_message(msgid, result, msgid, definition)
          elsif other_msgid = definition.search_msgid_fuzzy(msgid, used)
            used << other_msgid
            merge_fuzzy_message(msgid, result, other_msgid, definition) 
          elsif msgid.index("\000") and ( reference.msgstr(msgid).gsub("\000", '') == '' )
            # plural
            result[msgid] = "\000" * definition.nplural
          else
            change_reference_comment(msgid, result)
          end          
        end
        
        ###################################################################
        # msgids which are not used in reference are handled as obsolete. #
        ################################################################### 
        last_comment = result.comment(:last) || ''
        definition.each_msgid do |msgid|
          unless used.include?(msgid)
            last_comment << "\n"
            last_comment << definition.generate_po_entry(msgid).strip.gsub(/^/, '#. ')
            last_comment << "\n"
          end
        end
        result.set_comment(:last, last_comment)
        
        result
      end
      
      def merge_message(msgid, target, def_msgid, definition)
        merge_comment(msgid, target, def_msgid, definition)
        
        ############################################
        # check mismatch of msgid and msgid_plural #
        ############################################
        def_msgstr = definition[def_msgid]
        if msgid.index("\000")
          if def_msgstr.index("\000")
            # OK
            target[msgid] = def_msgstr			
          else
            # NG
            s = ''            
            definition.nplural.times {
              s << def_msgstr
              s << "\000"
            }
            target[msgid] = s
          end
        else
          if def_msgstr.index("\000")
            # NG
            target[msgid] = def_msgstr.split("\000")[0]
          else
            # OK
            target[msgid] = def_msgstr
          end
        end
      end
      
      # for the future
      def merge_fuzzy_message(msgid, target, def_msgid, definition)
        merge_message(msgid, target, def_msgid, definition)
      end
      
      def merge_comment(msgid, target, def_msgid, definition)
        ref_comment = target.comment(msgid)
        def_comment = definition.comment(def_msgid)
        
        normal_comment = []
        dot_comment = []
        semi_comment = []
        is_fuzzy = false
        
        def_comment.split(CRLF_RE).each do |l| 
          if NOT_SPECIAL_COMMENT_RE =~ l
            normal_comment << l
          end           
        end
        
        ref_comment.split(CRLF_RE).each do |l|
          if DOT_COMMENT_RE =~ l 
            dot_comment << l
          elsif SEMICOLON_COMMENT_RE =~ l
            semi_comment << l
          elsif FUZZY_RE =~ l
            is_fuzzy = true
          end
        end
        
        str = format_comment(normal_comment, dot_comment, semi_comment, is_fuzzy)
        target.set_comment(msgid, str)
      end
      
      def change_reference_comment(msgid, podata)
        normal_comment = []
        dot_comment = []
        semi_comment = []
        is_fuzzy = false
        
        podata.comment(msgid).split(CRLF_RE).each do |l|
          if DOT_COMMENT_RE =~ l 
            dot_comment << l
          elsif SEMICOLON_COMMENT_RE =~ l
            semi_comment << l
          elsif FUZZY_RE =~ l
            is_fuzzy = true
          else
            normal_comment << l
          end
        end
        
        str = format_comment(normal_comment, dot_comment, semi_comment, is_fuzzy)
        podata.set_comment(msgid, str)        
      end
      
      def format_comment(normal_comment, dot_comment, semi_comment, is_fuzzy)
        str = ''
        
        str << normal_comment.join("\n").gsub(/^#(\s*)/){|sss|
          if $1 == ""
            "# "
          else
            sss
          end
        }
        if normal_comment.size > 0
          str << "\n"
        end
        
        str << dot_comment.join("\n").gsub(/^#.(\s*)/){|sss|
          if $1 == ""
            "#. "
          else
            sss
          end
        }
        if dot_comment.size > 0
          str << "\n"
        end
        
        str << semi_comment.join("\n").gsub(/^#:\s*/, "#: ")
        if semi_comment.size > 0
          str << "\n"
        end
        
        if is_fuzzy
          str << "#, fuzzy\n"
        end
        
        str
      end
      
      def merge_header(target, definition)
        merge_comment('', target, '', definition)
        
        msg = target.msgstr('')
        def_msg = definition.msgstr('')
        if POT_DATE_EXTRACT_RE =~ msg
          time = $1
          def_msg = def_msg.sub(POT_DATE_RE, "POT-Creation-Date: #{time}")
        end
        
        target[''] = def_msg
      end
      
    end
    
  end  
  
end

module GetText::RMsgMerge #:nodoc:

  class Config #:nodoc:
    
    attr_accessor :defpo, :refpot, :output, :fuzzy, :update
    
    # update mode options
    attr_accessor :backup, :suffix
    
=begin      
The result is written back to def.po.
      --backup=CONTROL        make a backup of def.po
      --suffix=SUFFIX         override the usual backup suffix
The version control method may be selected via the --backup option or through
the VERSION_CONTROL environment variable.  Here are the values:
  none, off       never make backups (even if --backup is given)
  numbered, t     make numbered backups
  existing, nil   numbered if numbered backups exist, simple otherwise
  simple, never   always make simple backups
The backup suffix is `~', unless set with --suffix or the SIMPLE_BACKUP_SUFFIX
environment variable.
=end      
      
    def initialize
      @output = STDOUT
      @fuzzy = nil
      @update = nil
      @backup = ENV["VERSION_CONTROL"]
      @suffix= ENV["SIMPLE_BACKUP_SUFFIX"] || "~"
      @input_dirs = ["."]
    end
    
  end
  
end

module GetText
  
  module RMsgMerge
    extend GetText
    extend self

    bindtextdomain("rgettext")
    
    # constant values
    VERSION = GetText::VERSION
    DATE = %w($Date: 2007/07/21 15:03:05 $)[1]
    
    def check_options(config)
      opts = OptionParser.new
      opts.banner = _("Usage: %s def.po ref.pot [-o output.pot]") % $0
      #opts.summary_width = 80
      opts.separator("")
      opts.separator(_("Merges two Uniforum style .po files together. The def.po file is an existing PO file with translations. The ref.pot file is the last created PO file with up-to-date source references. ref.pot is generally created by rgettext."))
      opts.separator("")
      opts.separator(_("Specific options:"))
      
      opts.on("-o", "--output=FILE", _("write output to specified file")) do |out|
        unless FileTest.exist? out
          config.output = out
        else
          #$stderr.puts(_("File '%s' has already existed.") % out)
          #exit 1
        end
      end
      
      #opts.on("-F", "--fuzzy-matching")
      
      opts.on_tail("--version", _("display version information and exit")) do
        puts "#{$0} #{VERSION} (#{DATE})"
	puts "#{File.join(::Config::CONFIG["bindir"], ::Config::CONFIG["RUBY_INSTALL_NAME"])} #{RUBY_VERSION} (#{RUBY_RELEASE_DATE}) [#{RUBY_PLATFORM}]"
        exit
      end
      
      opts.parse!(ARGV)
      
      if ARGV.size != 2
        puts opts.help
        exit 1
      end
      
      config.defpo = ARGV[0]
      config.refpot = ARGV[1]
    end
    
    def run(reference = nil, definition = nil, out = STDOUT)
      config = GetText::RMsgMerge::Config.new
      config.refpot = reference
      config.defpo = definition
      config.output = out
      
      check_options(config)
      
      if config.defpo.nil?
        raise ArgumentError, _("definition po is not given.")
      elsif config.refpot.nil? 
        raise ArgumentError, _("reference pot is not given.")
      end
      
      parser = PoParser.new
      defpo = parser.parse_file(config.defpo, PoData.new, false)
      refpot = parser.parse_file(config.refstrrefstr, PoData.new, false)
      
      m = Merger.new
      result = m.merge(defpo, refpot)      
      p result if $DEBUG
      print result.generate_po if $DEBUG
      
      begin
        if out.is_a? String
          File.open(File.expand_path(out), "w+") do |file|
            file.write(result.generate_po)
          end
        else
          out.puts(result.generate_po)
        end
      ensure
        out.close
      end
    end    
    
  end
  
end



module GetText
  
  # Experimental
  def rmsgmerge(reference = nil, definition = nil, out = STDOUT)
    RMsgMerge.run(reference, definition, out)
  end

end



if $0 == __FILE__ then
  require 'pp'
  
  #parser = GetText::RMsgMerge::PoParser.new;
  #parser = GetText::PoParser.new;
  #pp parser.parse(ARGF.read)
  
  GetText.rmsgmerge
end
