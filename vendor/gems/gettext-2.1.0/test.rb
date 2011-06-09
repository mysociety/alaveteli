#!/usr/bin/ruby
## hello_gtk2.rb - sample for Ruby/GTK2
##
## Copyright (C) 2001-2006 Masao Mutoh
## This file is distributed under the same license as Ruby-GetText-Package.

require 'rubygems'
require 'gettext'
require 'gtk2'

class LocalizedWindow < Gtk::Window
  include GetText

  bindtextdomain("hello_gtk", :path => "locale", :output_charset => "utf-8")

  def initialize
    super
    signal_connect('delete-event') do
      Gtk.main_quit
    end

    add(Gtk::Label.new( "sdaf" )
    np_("Special", "An apple", "%{num} Apples", num)
    p_("File", "New")
    s_("File|New")
    n_("Special|An apple", "%{num} Apples", num)
  end
end

LocalizedWindow.new.show_all
Gtk.main


