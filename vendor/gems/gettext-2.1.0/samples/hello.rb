#!/usr/bin/ruby
# hello.rb - sample for _() and class.
#
# Copyright (C) 2001-2009 Masao Mutoh
# This file is distributed under the same license as Ruby-GetText-Package.

require 'rubygems'
require 'gettext'

class HelloWorld
  include GetText

  bindtextdomain("hello", :path => "locale")

  def hello
    print _("Hello World\n")
  end
end

if __FILE__ == $0
  a = HelloWorld.new

  a.hello # Show in your locale
  
  old = GetText.locale
  p old.to_s # Show current locale

  # Change the locale to "en".
  GetText.set_locale_all("en")
  p GetText.locale.to_s
  a.hello # Show in English

  # Retrive original locale
  GetText.set_locale(old)
  a.hello # Show in your locale
end
