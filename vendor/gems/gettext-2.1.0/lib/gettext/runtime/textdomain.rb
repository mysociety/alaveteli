=begin
  textdomain.rb - GetText::Textdomain

  Copyright (C) 2001-2009  Masao Mutoh
  Copyright (C) 2001-2003  Masahiro Sakai

      Masahiro Sakai    <s01397ms@sfc.keio.ac.jp>
      Masao Mutoh       <mutomasa at gmail.com>

  You may redistribute it and/or modify it under the same
  license terms as Ruby or LGPL.
=end

require 'gettext/core_ext/string'
require 'gettext/runtime/mofile'
require 'gettext/runtime/locale_path'

module GetText
  # GetText::TextDomain class manages mo-files of a textdomain.
  #
  # Usually, you don't need to use this class directly.
  #
  # Notice: This class is unstable. APIs will be changed.
  class TextDomain

    attr_reader :output_charset
    attr_reader :mofiles
    attr_reader :name

    @@cached = ! $DEBUG
    # Cache the mo-file or not.
    # Default is true. If $DEBUG is set then false.
    def self.cached?
      @@cached
    end

    # Set to cache the mo-file or not.
    # * val: true if cached, otherwise false.
    def self.cached=(val)
      @@cached = val
    end

    # Add default locale path. Usually you should use GetText.add_default_locale_path instead.
    # * path: a new locale path. (e.g.) "/usr/share/locale/%{lang}/LC_MESSAGES/%{name}.mo"
    #   ('locale' => "ja_JP", 'name' => "textdomain")
    # * Returns: the new DEFAULT_LOCALE_PATHS
    def self.add_default_locale_path(path)
      warn "Deprecated. Use GetText::LocalePath.add_default_rule instead."
      LocalePath.add_default_rule(path)
    end

    # Creates a new GetText::TextDomain.
    # * name: the textdomain name.
    # * topdir: the locale path ("%{topdir}/%{lang}/LC_MESSAGES/%{name}.mo") or nil.
    # * output_charset: output charset.
    # * Returns: a newly created GetText::TextDomain object.
    def initialize(name, topdir = nil, output_charset = nil)
      @name, @output_charset = name, output_charset

      @locale_path = LocalePath.new(@name, topdir)
      @mofiles = {}
    end
    
    # Translates the translated string.
    # * lang: Locale::Tag::Simple's subclass.
    # * msgid: the original message.
    # * Returns: the translated string or nil.
    def translate_singluar_message(lang, msgid)
      return "" if msgid == "" or msgid.nil?

      lang_key = lang.to_s

      mofile = nil
      if self.class.cached?
        mofile = @mofiles[lang_key]
      end
      unless mofile
        mofile = load_mo(lang)
      end
     
      if (! mofile) or (mofile ==:empty)
        return nil
      end

      msgstr = mofile[msgid]
      if msgstr and (msgstr.size > 0)
        msgstr
      elsif msgid.include?("\000")
        # Check "aaa\000bbb" and show warning but return the singluar part.
        ret = nil
        msgid_single = msgid.split("\000")[0]
        mofile.each{|key, val| 
          if key =~ /^#{Regexp.quote(msgid_single)}\000/
            # Usually, this is not caused to make po-files from rgettext.
            warn %Q[Warning: n_("#{msgid_single}", "#{msgid.split("\000")[1]}") and n_("#{key.gsub(/\000/, '", "')}") are duplicated.]
            ret = val
            break
          end
        }
        ret
      else
        ret = nil
        mofile.each{|key, val| 
          if key =~ /^#{Regexp.quote(msgid)}\000/
            ret = val.split("\000")[0]
            break
          end
        }
        ret
      end
    end

    DEFAULT_PLURAL_CALC = Proc.new{|n| n != 1}
    DEFAULT_SINGLE_CALC = Proc.new{|n| 0}

    # Translates the translated string.
    # * lang: Locale::Tag::Simple's subclass.
    # * msgid: the original message.
    # * msgid_plural: the original message(plural).
    # * Returns: the translated string as an Array ([[msgstr1, msgstr2, ...], cond]) or nil.
    def translate_plural_message(lang, msgid, msgid_plural)   #:nodoc:
      key = msgid + "\000" + msgid_plural
      msg = translate_singluar_message(lang, key)
      ret = nil
      if ! msg
        ret = nil
      elsif msg.include?("\000")
        # [[msgstr[0], msgstr[1], msgstr[2],...], cond]
        mofile = @mofiles[lang.to_posix.to_s]
        cond = (mofile and mofile != :empty) ? mofile.plural_as_proc : DEFAULT_PLURAL_CALC
        ret = [msg.split("\000"), cond]
      else
        ret = [[msg], DEFAULT_SINGLE_CALC]
      end
      ret
    end

    # Clear cached mofiles.
    def clear
      @mofiles = {}
    end

    # Set output_charset.
    # * charset: output charset.
    def output_charset=(charset)
      @output_charset = charset
      clear
    end

    private
    # Load a mo-file from the file.
    # lang is the subclass of Locale::Tag::Simple.
    def load_mo(lang)
      lang = lang.to_posix unless lang.kind_of? Locale::Tag::Posix
      lang_key = lang.to_s

      mofile = @mofiles[lang_key]
      if mofile
        if mofile == :empty
          return :empty
        elsif ! self.class.cached?
          mofile.update!
        end
        return mofile
      end

      path = @locale_path.current_path(lang)

      if path
        charset = @output_charset || lang.charset || Locale.charset || "UTF-8"
        @mofiles[lang_key] = MOFile.open(path, charset)
      else
        @mofiles[lang_key] = :empty
      end
    end
  end
end
