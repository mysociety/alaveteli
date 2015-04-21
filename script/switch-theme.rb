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
#
# You need to have a corresponding general.yml file called, for example:
#
#   config/general-whatdotheyknow-theme.yml
#   config/general-yourrighttoknow.yml

require 'tempfile'

$no_theme_name = 'none'
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
end.sort

$available_themes.unshift $no_theme_name

if $available_themes.empty?
  STDERR.puts "There were no theme directories found in '#{theme_directory}'"
  exit
end

def usage_and_exit
  STDERR.puts "Usage: #{$0} <THEME-NAME>"
  $available_themes.each do |theme_name|
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
theme_filename = File.join config_directory, "general-#{requested_theme}.yml"

if File.exists?(general_filename) && ! (File.symlink? general_filename)
  STDERR.puts "'#{general_filename}' exists, but isn't a symlink"
  exit 1
end

unless File.exists? theme_filename
  STDERR.puts "'#{theme_filename}' didn't exist"
  exit 1
end

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

symlink(File.basename(theme_filename),
        config_directory,
        "general.yml")

public_directory = File.join(alaveteli_directory, 'public')

if requested_theme == $no_theme_name
    File.unlink File.join(public_directory, 'alavetelitheme')
else
    symlink(File.join(full_theme_path, 'public'),
            public_directory,
            'alavetelitheme')

    symlink(full_theme_path,
            File.join(alaveteli_directory, 'lib', 'themes'),
            requested_theme)
end

STDERR.puts """Switched to #{requested_theme}!
You will need to:
  1. restart any development server you have running.
  2. run: bundle exec rake assets:clean
  3. run: bundle exec rake assets:precompile (if running in production mode)
"""
