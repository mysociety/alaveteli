#!/usr/bin/env ruby

require 'pathname'
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile',
  Pathname.new(__FILE__).realpath)

require 'rubygems'
require 'bundler/setup'

require 'rubocop'
require 'rubocop-performance'
require 'rubocop-rails'

CONFIG_FILE = File.join(File.dirname(__FILE__), '../.ruby-style.yml')
GEM_VERSIONS = {
  'rubocop': RuboCop::Version::STRING,
  'rubocop-performance': RuboCop::Performance::Version::STRING,
  'rubocop-rails': RuboCop::Rails::Version::STRING
}

print 'Current gem versions: '
p GEM_VERSIONS

def default_config
  tmp_dir = File.join(File.dirname(__FILE__), '../tmp')

  GEM_VERSIONS.inject({}) do |m, (r, v)|
    uri = URI(
      "https://raw.githubusercontent.com/rubocop/#{r}/v#{v}/config/default.yml"
    )

    hash = Digest::MD5.hexdigest(uri.to_s)
    tmp_path = File.join(tmp_dir, "rubocop-#{hash}.yml")

    File.write(tmp_path, Net::HTTP.get(uri)) unless File.exist?(tmp_path)

    if RUBY_VERSION < "3.1"
      yaml = YAML.load_file(tmp_path)
    else
      yaml = YAML.load_file(tmp_path, permitted_classes: [Regexp, Symbol])
    end

    m.deep_merge!(yaml)
  end
end

def current_config
  YAML.load_file(CONFIG_FILE)
end

def merge_config(default, current)
  config = { 'AllCops' => current['AllCops'] }
  non_cops_groupings_from_config(current).each do |g|
    config[g] = current[g]
  end

  cops_from_config(default).each do |cop|
    c = current[cop]

    if c
      config[cop] = c
    else
      config[cop] = { 'Enabled' => false }
    end
  end

  config
end

def non_cops_groupings_from_config(config)
  config.keys.select { |k| k == k.downcase }
end

def cops_from_config(config)
  config.keys - non_cops_groupings_from_config(config) - ['AllCops']
end

def groupings_from_config(config)
  cops_from_config(config).map { |c| c.split('/').first }.uniq
end

def write_config(config, comments)
  yaml = config.sort.to_h.to_yaml

  # add lines between cops
  yaml.gsub!(/^(?!AllCops)([^ -]+:)$/, "\n\\1")

  # increase indent of array items
  yaml.gsub!(/^( *- )/, '  \1')

  non_cops_groupings_from_config(config).each do |g|
    # move non-cop groupings keys to top
    yaml.gsub!(/(---\n)(.*)\n^(#{g}:.*)/m, "\\1\\3\n\\2")
  end

  groupings_from_config(config).each do |g|
    # add headers for each grouping
    yaml.sub!(g + '/', '#' * 20 + " #{g} " + '#' * 20 + "\n\n#{g}/")
  end

  comments.each do |cop, comment_lines|
    yaml.gsub!(/^(#{cop}:)/, "#{comment_lines.join("\n")}\n\\1")
  end

  File.write(CONFIG_FILE, yaml)
end

def cop_comments
  comments = {}
  current_section = []

  File.readlines(CONFIG_FILE).each do |line|
    if line.match?('^(# .*|#)$')
      current_section << line.strip
    elsif !current_section.empty? && line.match?(/^\w/)
      cop_name = line.split(':').first
      comments[cop_name] = current_section
      current_section = []
    end
  end

  comments
end

write_config(merge_config(default_config, current_config), cop_comments)
puts "RuboCop configuration at #{File.expand_path(CONFIG_FILE)} has been updated"
puts "Please manually check cops which have been renamed"
