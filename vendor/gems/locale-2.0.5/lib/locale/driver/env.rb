=begin
  locale/env.rb 

  Copyright (C) 2008  Masao Mutoh

  You may redistribute it and/or modify it under the same
  license terms as Ruby.

  Original: Ruby-GetText-Package-1.92.0.

  $Id: env.rb 27 2008-12-03 15:06:50Z mutoh $
=end

require 'locale/tag'
require 'locale/taglist'

module Locale 
  module Driver
    # Locale::Driver::Env module.
    # Detect the user locales and the charset.
    # All drivers(except CGI) refer environment variables first and use it 
    # as the locale if it's defined.
    # This is a low-level module. Application shouldn't use this directly.
    module Env
      module_function

      # Gets the locale from environment variable. (LC_ALL > LC_MESSAGES > LANG)
      # Returns: the locale as Locale::Tag::Posix.
      def locale
        # At least one environment valiables should be set on *nix system.
        [ENV["LC_ALL"], ENV["LC_MESSAGES"], ENV["LANG"]].each do |loc|
          if loc != nil and loc.size > 0
            return Locale::Tag::Posix.parse(loc)
          end
        end
        nil
      end

      # Gets the locales from environment variables. (LANGUAGE > LC_ALL > LC_MESSAGES > LANG)
      # * Returns: an Array of the locale as Locale::Tag::Posix or nil.
      def locales
        if (locales = ENV["LANGUAGE"])
          Locale::TagList.new(locales.split(/:/).collect{|v| Locale::Tag::Posix.parse(v)})
        elsif (loc = locale)
          Locale::TagList.new([loc])
        else
          nil
        end
      end

      # Gets the charset from environment variable or return nil.
      # * Returns: the system charset.
      def charset  # :nodoc:
        if loc = locale
          loc.charset
        else
          nil
        end
      end
      
    end
  end
end

