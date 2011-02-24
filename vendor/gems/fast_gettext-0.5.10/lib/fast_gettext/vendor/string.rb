#! /usr/bin/ruby
=begin
  string.rb - Extension for String.

  Copyright (C) 2005,2006 Masao Mutoh

  You may redistribute it and/or modify it under the same
  license terms as Ruby.
=end

# Extension for String class. This feature is included in Ruby 1.9 or later.
begin
  raise ArgumentError if ("a %{x}" % {:x=>'b'}) != 'a b'
rescue ArgumentError
  # either we are on vanilla 1.8(call with hash raises ArgumentError)
  # or someone else already patched % but did it wrong
  class String
    alias :_fast_gettext_old_format_m :% # :nodoc:

    PERCENT_MATCH_RE = Regexp.union(
      /%%/,
      /%\{([-\.\w]+)\}/,
      /%<([-\.\w]+)>(.*?\d*\.?\d*[bBdiouxXeEfgGcps])/
    )

    # call-seq:
    #  %(hash)
    #
    #  Default: "%s, %s" % ["Masao", "Mutoh"]
    #  Extended:
    #     "%{firstname}, %{lastname}" % {:firstname=>"Masao",:lastname=>"Mutoh"} == "Masao Mutoh"
    #     with field type such as d(decimal), f(float), ...
    #     "%<age>d, %<weight>.1f" % {:age => 10, :weight => 43.4} == "10 43.4"
    # This is the recommanded way for Ruby-GetText
    # because the translators can understand the meanings of the keys easily.
    def %(args)
      if args.kind_of? Hash
        #stringify keys
        replace = {}
        args.each{|k,v|replace[k.to_s]=v}

        #replace occurances
        ret = dup
        ret.gsub!(PERCENT_MATCH_RE) do |match|
          if match == '%%'
            '%'
          elsif $1
            replace.has_key?($1) ? replace[$1] : match
          elsif $2
            replace.has_key?($2) ? sprintf("%#{$3}", replace[$2]) : match
          end
        end
        ret
      else
        ret = gsub(/%([{<])/, '%%\1')
        ret._fast_gettext_old_format_m(args)
      end
    end
  end
end

# 1.9.1 if you misspell a %{key} your whole page would blow up, no thanks...
begin
  ("%{b}" % {:a=>'b'})
rescue KeyError
  class String
    alias :_fast_gettext_old_format_m :%
    def %(*args)
      begin
        _fast_gettext_old_format_m(*args)
      rescue KeyError
        self
      end
    end
  end
end