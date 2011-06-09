#!/usr/bin/ruby
# hello_tk.rb - sample for Ruby/TK
#
# Copyright (C) 2004 Masao Mutoh
# This file is distributed under the same license as Ruby-GetText-Package.

require 'rubygems'
require 'gettext'
require 'tk'

include GetText
bindtextdomain("hello_tk", :path => "locale")

TkLabel.new {
  text _("hello, tk world")
  pack
}

Tk.mainloop
