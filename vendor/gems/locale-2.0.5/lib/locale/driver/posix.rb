=begin
  locale/posix.rb 

  Copyright (C) 2002-2008  Masao Mutoh

  You may redistribute it and/or modify it under the same
  license terms as Ruby.

  Original: Ruby-GetText-Package-1.92.0.

  $Id: posix.rb 27 2008-12-03 15:06:50Z mutoh $
=end

require File.join(File.dirname(__FILE__), 'env')

module Locale 
  # Locale::Driver::Posix module for Posix OS (Unix)
  # Detect the user locales and the charset.
  # This is a low-level class. Application shouldn't use this directly.
  module Driver
    module Posix
      $stderr.puts self.name + " is loaded." if $DEBUG

      module_function
      # Gets the locales from environment variables. (LANGUAGE > LC_ALL > LC_MESSAGES > LANG)
      # Only LANGUAGE accept plural languages such as "nl_BE;
      # * Returns: an Array of the locale as Locale::Tag::Posix or nil.
      def locales
        ::Locale::Driver::Env.locales
      end

      # Gets the charset from environment variable or the result of
      # "locale charmap" or nil.
      # * Returns: the system charset.
      def charset
        charset = ::Locale::Driver::Env.charset
        unless charset
          charset = `locale charmap`.strip
          unless $? && $?.success?
            charset = nil
          end
        end
        charset
      end
    end
  end
  @@locale_driver_module = Driver::Posix
end

