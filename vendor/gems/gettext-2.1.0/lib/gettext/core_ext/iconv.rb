# encoding: utf-8
=begin
  iconv.rb - Pseudo Iconv class. Supports Iconv.iconv, Iconv.conv.

  For Matz Ruby:
  If you don't have iconv but glib2, this library uses glib2 iconv functions.

  For JRuby:
  Use Java String class to convert strings.

  Copyright (C) 2004-2009  Masao Mutoh

  You may redistribute it and/or modify it under the same
  license terms as Ruby or LGPL.
=end

begin
  require 'iconv.so'
rescue LoadError
  # Pseudo Iconv class
  # 
  # ==== For Matz Ruby:
  # If you don't have iconv but Ruby/GLib2, this library uses Ruby/GLib2's 
  # iconv functions.
  #
  # Ruby/GLib is a module which is provided from Ruby-GNOME2 Project. 
  # You can get binaries for Win32(One-Click Ruby Installer).
  # <URL: http://ruby-gnome2.sourceforge.jp/>
  # ==== For JRuby:
  # Use Java String class to convert strings.
  class Iconv
    module Failure; end
    class InvalidEncoding < ArgumentError;  include Failure; end
    class IllegalSequence < ArgumentError;  include Failure; end
    class InvalidCharacter < ArgumentError; include Failure; end

    if RUBY_PLATFORM =~ /java/
      def self.conv(to, from, str)
        raise InvalidCharacter, "the 3rd argument is nil" unless str
        begin
          str = java.lang.String.new(str.unpack("C*").to_java(:byte), from)
          str.getBytes(to).to_ary.pack("C*")
        rescue java.io.UnsupportedEncodingException
          raise InvalidEncoding
        end
      end
    else
      begin
        require 'glib2'
      
        def self.check_glib_version?(major, minor, micro) # :nodoc:
          (GLib::BINDING_VERSION[0] > major ||
           (GLib::BINDING_VERSION[0] == major && 
            GLib::BINDING_VERSION[1] > minor) ||
           (GLib::BINDING_VERSION[0] == major && 
            GLib::BINDING_VERSION[1] == minor &&
            GLib::BINDING_VERSION[2] >= micro))
        end
        
        if check_glib_version?(0, 11, 0)
          # This is a function equivalent of Iconv.iconv.
          # * to: encoding name for destination
          # * from: encoding name for source
          # * str: strings to be converted
          # * Returns: Returns an Array of converted strings.
          def self.conv(to, from, str)
            begin
              GLib.convert(str, to, from)
            rescue GLib::ConvertError => e
              case e.code
              when GLib::ConvertError::NO_CONVERSION
                raise InvalidEncoding.new(str)
              when GLib::ConvertError::ILLEGAL_SEQUENCE
                raise IllegalSequence.new(str)
              else
                raise InvalidCharacter.new(str)
              end
            end
          end
        else
          def self.conv(to, from, str) # :nodoc:
            begin
              GLib.convert(str, to, from)
            rescue
              raise IllegalSequence.new(str)
            end
          end
        end
      rescue LoadError
        def self.conv(to, from, str) # :nodoc:
          warn "Iconv was not found." if $DEBUG
          str
        end
      end
    end
    def self.iconv(to, from, str)
      conv(to, from, str).split(//)
    end
  end
end

if __FILE__ == $0
  puts Iconv.iconv("EUC-JP", "UTF-8", "ほげ").join
  begin
    puts Iconv.iconv("EUC-JP", "EUC-JP", "ほげ").join
  rescue Iconv::Failure
    puts $!
    puts $!.class
  end
end
