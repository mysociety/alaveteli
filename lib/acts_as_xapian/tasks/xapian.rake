require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'active_record'

namespace :xapian do
    # Parameters - specify "flush=true" to save changes to the Xapian database
    # after each model that is updated. This is safer, but slower. Specify
    # "verbose=true" to print model name as it is run.
    desc 'Updates Xapian search index with changes to models since last call'
    task :update_index => :environment do
        ActsAsXapian.update_index(ENV['flush'], ENV['verbose'])
    end

    # Parameters - specify 'models="PublicBody User"' to say which models
    # you index with Xapian.

    # This totally rebuilds the database, so you will want to restart
    # any web server afterwards to make sure it gets the changes,
    # rather than still pointing to the old deleted database. Specify
    # "verbose=true" to print model name as it is run.  By default,
    # all of the terms, values and texts are reindexed.  You can
    # suppress any of these by specifying, for example, "texts=false".
    # You can specify that only certain terms should be updated by
    # specifying their prefix(es) as a string, e.g. "terms=IV" will
    # index the two terms I and V (and "terms=false" will index none,
    # and "terms=true", the default, will index all)


    desc 'Completely rebuilds Xapian search index (must specify all models)'
    task :rebuild_index => :environment do
        def coerce_arg(arg, default)
	    if arg == "false"
	        return false
            elsif arg == "true"
                return true
            elsif arg.nil?
	        return default
            else
                return arg
            end
	end
        raise "specify ALL your models with models=\"ModelName1 ModelName2\" as parameter" if ENV['models'].nil?
        ActsAsXapian.rebuild_index(ENV['models'].split(" ").map{|m| m.constantize}, 
	coerce_arg(ENV['verbose'], false),
        coerce_arg(ENV['terms'], true),
        coerce_arg(ENV['values'], true),
        coerce_arg(ENV['texts'], true))
    end

    # Parameters - are models, query, offset, limit, sort_by_prefix,
    # collapse_by_prefix
    desc 'Run a query, return YAML of results'
    task :query => :environment do
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

