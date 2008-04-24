require 'rubygems'
require 'rake'
require 'rake/testtask'

namespace :xapian do
    # Parameters - specify "flush=true" to save changes to the Xapian database
    # after each model that is updated. This is safer, but slower.
    desc 'Updates Xapian search index with changes to models since last call'
    task :update_index do
        ActsAsXapian.update_index(ENV['flush'] ? true : false)
    end

    # Parameters - specify 'models="PublicBody User"' to say which models
    # you index with Xapian.
    desc 'Completely rebuilds Xapian search index (must specify all models)'
    task :rebuild_index do
        raise "specify ALL your models with models=\"ModelName1 ModelName2\" as parameter" if ENV['models'].nil?
        ActsAsXapian.rebuild_index(ENV['models'].split(" ").map{|m| m.constantize})
    end

    # Parameters - are models, query, first_result, results_per_page, sort_by_prefix, collapse_by_prefix
    desc 'Run a query, return YAML of results'
    task :query do
        raise "specify models=\"ModelName1 ModelName2\" as parameter" if ENV['models'].nil?
        raise "specify query=\"your terms\" as parameter" if ENV['query'].nil?
        s = ActsAsXapian::Search.new(ENV['models'].split(" ").map{|m| m.constantize}, 
            ENV['query'], 
            ENV['first_result'] || 0, ENV['results_per_page'] || 10,  
            ENV['sort_by_prefix'] || nil, ENV['collapse_by_prefix'] || nil
        )
        STDOUT.puts(s.results.to_yaml)
    end
end

