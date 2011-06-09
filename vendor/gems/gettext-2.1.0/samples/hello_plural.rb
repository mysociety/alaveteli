#!/usr/bin/ruby
# hello_plural.po - sample for n_() and class.
#
# Copyright (C) 2002-2006 Masao Mutoh
# This file is distributed under the same license as Ruby-GetText-Package.

require 'rubygems'
require 'gettext'

class HelloPlural
  include GetText

  def initialize
    bindtextdomain("hello_plural", :path => "locale")
  end

  def hello
    (0..2).each do |v|
      puts n_("There is an apple.\n", "There are %{num} apples.\n", v) % {:num => v}
    end
  end
end

hello = HelloPlural.new

hello.hello
