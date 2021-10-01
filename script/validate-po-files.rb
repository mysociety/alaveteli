#!/usr/bin/env ruby

require 'pathname'
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile',
  Pathname.new(__FILE__).realpath)

require 'rubygems'
require 'gettext/mo'
require 'gettext/po_parser'

MATCH = /\{\{([^\}]+)\}\}/

locale = ARGV[0]
locale ||= '*'

po_files = Dir.glob("locale*/#{locale}/*.po").sort
po_files.each do |po_file|
  errors = []

  messages = GetText::POParser.new.parse_file(po_file, GetText::MO.new)
  messages.each do |message, translation|
    next unless translation

    strings = message.gsub(MATCH).to_a
    strings.reject! { |string| translation =~ /#{string}/ }

    next if strings.empty?

    errors << "Translation for `#{message}` is missing #{strings.join ', '}"
  end

  next if errors.empty?

  errors.each do |error|
    puts "#{po_file}: #{error}"
  end
end
