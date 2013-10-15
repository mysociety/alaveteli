#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# A simple script to swap around your Alaveteli themes when you're
# hacking on Alaveteli.  By default this assumes that you have an
# 'alaveteli-themes' directory at the same level as your alaveteli git
# repository, e.g.:
#
# alaveteli
# ├── app
# ├── cache
# ...
# └── vendor
# alaveteli-themes/
# ├── alavetelitheme
# ├── asktheeu-theme
# ├── chiediamo-theme
# ├── ipvtheme
# ├── queremossabertheme
# ├── tuderechoasaber-theme
# ├── whatdotheyknow-theme
# └── yourrighttoknow
#
# However, you can override the location of your themes directory with
# the environment variable ALAVETELI_THEMES_DIR.

require 'tempfile'

theme_directory = ENV['ALAVETELI_THEMES_DIR']
alaveteli_directory = File.expand_path(File.join(File.dirname(__FILE__),
                                                 ".."))
unless theme_directory
  theme_directory = File.expand_path File.join(alaveteli_directory,
                                               '..',
                                               'alaveteli-themes')
end

unless File.exists? theme_directory
  STDERR.puts "The theme directory '#{theme_directory}' didn't exist."
  exit 1
end

# Assume that any directory directly under theme_directory is a theme:
$available_themes = Dir.entries(theme_directory).find_all do |local_theme_name|
  next if [".", ".."].index local_theme_name
  next unless local_theme_name
  full_path = File.join theme_directory, local_theme_name
  next unless File.directory? full_path
  next unless File.directory? File.join(full_path, '.git')
  local_theme_name
end

if $available_themes.empty?
  STDERR.puts "There were no theme directories found in '#{theme_directory}'"
  exit
end

def usage_and_exit
  STDERR.puts "Usage: #{$0} <THEME-NAME>"
  $available_themes.sort.each do |theme_name|
    STDERR.puts "  #{theme_name}"
  end
  exit 1
end

usage_and_exit unless ARGV.length == 1
requested_theme = ARGV[0]
usage_and_exit unless $available_themes.include? requested_theme

full_theme_path = File.join theme_directory, requested_theme

config_directory = File.join alaveteli_directory, 'config'
general_filename = File.join config_directory, "general.yml"

unless File.exists? general_filename
  STDERR.puts "The configuration file '#{general_filename}' didn't exist"
  exit 1
end

original_lines = File.readlines(general_filename)

marker_re = /(\S+)(\s*#\s*SWITCHABLE.*)/

unless original_lines.grep marker_re
  STDERR.puts """Error: the theme URL to be switched should be suffixed
with '# SWITCHABLE' in '#{general_filename}'"""
  exit 1
end

# Copy over the new file atomically by writing to a temporary file and
# renaming into place:
tmp = Tempfile.new 'general.yml', config_directory
open(tmp.path, 'w') do |f|
  original_lines.each do |line|
    f.puts line.gsub marker_re, "'#{full_theme_path}'\\2"
  end
end
File.rename tmp.path, general_filename

def symlink target, link_directory, link_name
  tmp = Tempfile.new link_name, link_directory
  if system("ln", "-sfn", target, tmp.path)
    full_link_name = File.join(link_directory, link_name)
    begin
      File.rename tmp.path, full_link_name
    rescue Errno::EISDIR
      STDERR.puts "Couldn't overwrite #{full_link_name} since it's a directory"
      exit 1
    end
  else
    STDERR.puts "Failed to create a symlink from #{tmp.path} to #{target}"
    exit 1
  end
end

symlink(File.join(full_theme_path, 'public'),
        File.join(alaveteli_directory, 'public'),
        'alavetelitheme')

symlink(full_theme_path,
        File.join(alaveteli_directory, 'vendor', 'plugins'),
        requested_theme)

STDERR.puts """Switched to #{requested_theme}!
You will need to restart any development server and may need to change
locale settings in:
    #{general_filename}"""
