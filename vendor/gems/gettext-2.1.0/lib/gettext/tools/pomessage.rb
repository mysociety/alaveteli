module GetText
  class ParseError < StandardError
  end

  # Contains data related to the expression or sentence that
  # is to be translated.
  class PoMessage
    PARAMS = {
      :normal => [:msgid],
      :plural => [:msgid, :msgid_plural],
      :msgctxt => [:msgctxt, :msgid],
      :msgctxt_plural => [:msgctxt, :msgid, :msgid_plural]
    }

    @@max_line_length = 70

    # Sets the max line length.
    def self.max_line_length=(len)
      @@max_line_length = len
    end

    # Gets the max line length.
    def self.max_line_length
      @@max_line_length
    end

    # Required
    attr_accessor :type          # :normal, :plural, :msgctxt, :msgctxt_plural 
    attr_accessor :msgid
    # Options
    attr_accessor :msgid_plural
    attr_accessor :msgctxt
    attr_accessor :sources    # ["file1:line1", "file2:line2", ...]
    attr_accessor :comment

    # Create the object. +type+ should be :normal, :plural, :msgctxt or :msgctxt_plural. 
    def initialize(type)
      @type = type
      @sources = []
      @param_type = PARAMS[@type]
    end

    # Support for extracted comments. Explanation s.
    # http://www.gnu.org/software/gettext/manual/gettext.html#Names
    def add_comment(new_comment)
      if (new_comment and ! new_comment.empty?)
        @comment ||= ""
        @comment += new_comment
      end
      to_s
    end

    # Returns a parameter representation suitable for po-files
    # and other purposes.
    def escaped(param_name)
      orig = self.send param_name
      orig.gsub(/"/, '\"').gsub(/\r/, '')
    end

    # Checks if the other translation target is mergeable with
    # the current one. Relevant are msgid and translation context (msgctxt).
    def ==(other)
      other.msgid == self.msgid && other.msgctxt == self.msgctxt
    end

    # Merges two translation targets with the same msgid and returns the merged
    # result. If one is declared as plural and the other not, then the one
    # with the plural wins.
    def merge(other)
      return self unless other
      raise ParseError, "Translation targets do not match: \n" \
      "  self: #{self.inspect}\n  other: '#{other.inspect}'" unless self == other
      if other.msgid_plural && !self.msgid_plural
        res = other
        unless (res.sources.include? self.sources[0])
          res.sources += self.sources
          res.add_comment(self.comment)
        end
      else
        res = self
        unless (res.sources.include? other.sources[0])
          res.sources += other.sources
          res.add_comment(other.comment)
        end
      end
      res
    end

    # Output the po message for the po-file.
    def to_po_str
      raise "msgid is nil." unless @msgid
      raise "sources is nil." unless @sources

      str = ""
      # extracted comments
      if comment
        comment.split("\n").each do |comment_line|
          str << "\n#. #{comment_line.strip}"
        end
      end

      # references
      curr_pos = @@max_line_length
      sources.each do |e|
        if curr_pos + e.size > @@max_line_length
          str << "\n#:"
          curr_pos = 3
        else
          curr_pos += (e.size + 1)
        end
        str << " " << e
      end

      # msgctxt, msgid, msgstr
      str << "\nmsgctxt \"" << msgctxt << "\"" if msgctxt?
      str << "\nmsgid \"" << escaped(:msgid) << "\"\n"
      if plural?
        str << "msgid_plural \"" << escaped(:msgid_plural) << "\"\n"
        str << "msgstr[0] \"\"\n"
        str << "msgstr[1] \"\"\n"
      else
        str << "msgstr \"\"\n"
      end
      str
    end

    # Returns true if the type is kind of msgctxt.
    # And if this is a kind of msgctxt and msgctxt property 
    # is nil, then raise an RuntimeException.
    def msgctxt?
      if [:msgctxt, :msgctxt_plural].include? @type
        raise "This PoMessage is a kind of msgctxt but the msgctxt property is nil. msgid: #{msgid}" unless @msgctxt
        true
      end
    end

    # Returns true if the type is kind of plural.
    # And if this is a kind of plural and msgid_plural property 
    # is nil, then raise an RuntimeException.
    def plural?
      if [:plural, :msgctxt_plural].include? @type
        raise "This PoMessage is a kind of plural but the msgid_plural property is nil. msgid: #{msgid}" unless @msgid_plural
        true
      end
    end

    private

    # sets or extends the value of a translation target params like msgid,
    # msgctxt etc.
    #   param is symbol with the name of param
    #   value - new value
    def set_value(param, value)
      send "#{param}=", (send(param) || '') + value.gsub(/\n/, '\n')
    end

    public
    # For backward comatibility. This doesn't support "comment".
    # ary = [msgid1, "file1:line1", "file2:line"]
    def self.new_from_ary(ary)
      ary = ary.dup
      msgid = ary.shift
      sources = ary
      type = :normal
      msgctxt = nil
      msgid_plural = nil
      
      if msgid.include? "\004"
        msgctxt, msgid = msgid.split(/\004/)
        type = :msgctxt
      end
      if msgid.include? "\000"
        ids = msgid.split(/\000/)
        msgid = ids[0]
        msgid_plural = ids[1]
        if type == :msgctxt
          type = :msgctxt_plural
        else
          type = :plural
        end
      end
      ret = self.new(type)
      ret.msgid = msgid
      ret.sources = sources
      ret.msgctxt = msgctxt
      ret.msgid_plural = msgid_plural
      ret
    end

    def [](number)
      param = @param_type[number]
      raise ParseError, 'no more string parameters expected' unless param
      send param
    end
  end
  
end
