require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'activerecord'
require File.dirname(__FILE__) + '/../lib/acts_as_xapian.rb'

namespace :xapian do
    # Parameters - specify "flush=true" to save changes to the Xapian database
    # after each model that is updated. This is safer, but slower. Specify
    # "verbose=true" to print model name as it is run.
    desc 'Updates Xapian search index with changes to models since last call'
    task (:update_index => :environment) do
        ActsAsXapian.update_index(ENV['flush'] ? true : false, ENV['verbose'] ? true : false)
    end

    # Parameters - specify 'models="PublicBody User"' to say which models
    # you index with Xapian.
    # This totally rebuilds the database, so you will want to restart any
    # web server afterwards to make sure it gets the changes, rather than
    # still pointing to the old deleted database. Specify "verbose=true" to
    # print model name as it is run.
    desc 'Completely rebuilds Xapian search index (must specify all models)'
    task (:rebuild_index => :environment) do
        raise "specify ALL your models with models=\"ModelName1 ModelName2\" as parameter" if ENV['models'].nil?
        ActsAsXapian.rebuild_index(ENV['models'].split(" ").map{|m| m.constantize}, ENV['verbose'] ? true : false)
    end

    # Parameters - are models, query, offset, limit, sort_by_prefix,
    # collapse_by_prefix
    desc 'Run a query, return YAML of results'
    task (:query => :environment) do
        raise "specify models=\"ModelName1 ModelName2\" as parameter" if ENV['models'].nil?
        raise "specify query=\"your terms\" as parameter" if ENV['query'].nil?
        s = ActsAsXapian::Search.new(ENV['models'].split(" ").map{|m| m.constantize}, 
            ENV['query'],
            :offset => (ENV['offset'] || 0), :limit => (ENV['limit'] || 10),
            :sort_by_prefix => (ENV['sort_by_prefix'] || nil), 
            :collapse_by_prefix => (ENV['collapse_by_prefix'] || nil)
        )
        STDOUT.puts(s.results.to_yaml)
    end
end

