=begin
  gettext/textdomain_manager - GetText::TextDomainManager class

  Copyright (C) 2009  Masao Mutoh

  You may redistribute it and/or modify it under the same
  license terms as Ruby or LGPL.

=end

require 'gettext/runtime/class_info'
require 'gettext/runtime/textdomain'
require 'gettext/runtime/textdomain_group'

module GetText

  module TextDomainManager

    @@textdomain_pool = {}
    @@textdomain_group_pool = {}

    @@output_charset = nil
    @@gettext_classes = []

    @@singular_message_cache = {}
    @@plural_message_cache = {}
    @@cached = ! $DEBUG

    extend self
    
    # Find textdomain by name
    def textdomain_pool(domainname)
      @@textdomain_pool[domainname]
    end

    # Set the value whether cache messages or not. 
    # true to cache messages, otherwise false.
    #
    # Default is true. If $DEBUG is false, messages are not checked even if
    # this value is true.
    def cached=(val)
      @@cached = val
      TextDomain.cached = val
    end
    
    # Return the cached value.
    def cached?
      TextDomain.cached?
    end

    # Gets the output charset.
    def output_charset
      @@output_charset 
    end
    
    # Sets the output charset.The program can have a output charset.
    def output_charset=(charset)
      @@output_charset = charset
      @@textdomain_pool.each do |key, textdomain|
        textdomain.output_charset = charset
      end
    end
    
    # bind textdomain to the class.
    def bind_to(klass, domainname, options = {})
      warn "Bind the domain '#{domainname}' to '#{klass}'. " if $DEBUG

      charset = options[:output_charset] || self.output_charset
      textdomain = create_or_find_textdomain(domainname,options[:path],charset)
      target_klass = ClassInfo.normalize_class(klass)
      create_or_find_textdomain_group(target_klass).add(textdomain)
      @@gettext_classes << target_klass unless @@gettext_classes.include? target_klass
      
      textdomain
    end
    
    def each_textdomains(klass) #:nodoc:
      lang = Locale.candidates[0]
      ClassInfo.related_classes(klass, @@gettext_classes).each do |target|
        msg = nil
        if group = @@textdomain_group_pool[target]
          group.textdomains.each do |textdomain|
            yield textdomain, lang
          end
        end
      end
    end

    # Translates msgid, but if there are no localized text, 
    # it returns a last part of msgid separeted "div" or whole of the msgid with no "div".
    #
    # * msgid: the message id.
    # * div: separator or nil.
    # * Returns: the localized text by msgid. If there are no localized text, 
    #   it returns a last part of msgid separeted "div".
    def translate_singluar_message(klass, msgid, div = nil)
      klass = ClassInfo.normalize_class(klass)
      key = [Locale.current, klass, msgid, div].hash
      msg = @@singular_message_cache[key]
      return msg if msg and @@cached
      # Find messages from related classes.
      each_textdomains(klass) do |textdomain, lang|
        msg = textdomain.translate_singluar_message(lang, msgid)
        break if msg
      end
      
      # If not found, return msgid.
      msg ||= msgid
      if div and msg == msgid
        if index = msg.rindex(div)
          msg = msg[(index + 1)..-1]
        end
      end
      @@singular_message_cache[key] = msg
    end
    
    # This function is similar to the get_singluar_message function 
    # as it finds the message catalogs in the same way. 
    # But it takes two extra arguments for plural form.
    # The msgid parameter must contain the singular form of the string to be converted. 
    # It is also used as the key for the search in the catalog. 
    # The msgid_plural parameter is the plural form. 
    # The parameter n is used to determine the plural form. 
    # If no message catalog is found msgid1 is returned if n == 1, otherwise msgid2. 
    # And if msgid includes "div", it returns a last part of msgid separeted "div".
    #
    # * msgid: the singular form with "div". (e.g. "Special|An apple", "An apple")
    # * msgid_plural: the plural form. (e.g. "%{num} Apples")
    # * n: a number used to determine the plural form.
    # * div: the separator. Default is "|".
    # * Returns: the localized text which key is msgid_plural if n is plural(follow plural-rule) or msgid.
    #   "plural-rule" is defined in po-file.
    #
    # or
    #
    # * [msgid, msgid_plural] : msgid and msgid_plural an Array
    # * n: a number used to determine the plural form.
    # * div: the separator. Default is "|".
    def translate_plural_message(klass, arg1, arg2, arg3 = "|", arg4 = "|")
      klass = ClassInfo.normalize_class(klass)
      # parse arguments
      if arg1.kind_of?(Array)
        msgid = arg1[0]
        msgid_plural = arg1[1]
        n = arg2
        if arg3 and arg3.kind_of? Numeric
          raise ArgumentError, _("3rd parmeter is wrong: value = %{number}") % {:number => arg3}
        end
        div = arg3
      else
        msgid = arg1
        msgid_plural = arg2
        n = arg3
        div = arg4
      end

      key = [Locale.current, klass, msgid, msgid_plural, div].hash
      msgs = @@plural_message_cache[key]
      unless (msgs and @@cached)
        # Find messages from related classes.
        msgs = nil
        each_textdomains(klass) do |textdomain, lang|
          msgs = textdomain.translate_plural_message(lang, msgid, msgid_plural)
          break if msgs
        end
        
        msgs = [[msgid, msgid_plural], TextDomain::DEFAULT_PLURAL_CALC] unless msgs
        
        msgstrs = msgs[0]
        if div and msgstrs[0] == msgid and index = msgstrs[0].rindex(div)
          msgstrs[0] = msgstrs[0][(index + 1)..-1]
        end
        @@plural_message_cache[key] = msgs
      end
      
      # Return the singular or plural message.
      msgstrs = msgs[0]
      plural = msgs[1].call(n)
      return msgstrs[plural] if plural.kind_of?(Numeric)
      return plural ? msgstrs[1] : msgstrs[0]
    end

    # for testing.
    def clear_all_textdomains
      @@textdomain_pool = {}
      @@textdomain_group_pool = {}
      @@gettext_classes = []
      clear_caches
    end

    # for testing.
    def clear_caches
      @@singular_message_cache = {}
      @@plural_message_cache = {}
    end

    def create_or_find_textdomain_group(klass) #:nodoc:
      group = @@textdomain_group_pool[klass]
      return group if group
      
      @@textdomain_group_pool[klass] = TextDomainGroup.new
    end
    
    def create_or_find_textdomain(name, path, charset)#:nodoc:
      textdomain = @@textdomain_pool[name]
      return textdomain if textdomain
      
      @@textdomain_pool[name] = TextDomain.new(name, path, charset)
    end
  end
end
