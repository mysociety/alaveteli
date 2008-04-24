# acts_as_xapian/lib/acts_as_xapian.rb:
# Xapian full text search in Ruby on Rails.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: acts_as_xapian.rb,v 1.9 2008-04-24 13:08:11 francis Exp $

# TODO:
# Test :eager_load
# Test :if
# Reverse sorting?

# Documentation
# =============
#
# Xapian is a full text search engine library, which has Ruby bindings.
# acts_as_xapian adds support for it to Rails. It is an alternative to
# acts_as_lucene or acts_as_ferret.
#
# Xapian is an *offline indexing* search library - only one process can have
# the database open for writing at once, and others that try meanwhile are
# unceremoniously kicked out. For this reason, acts_as_xapian does not support
# automatic writing to the database when your models change.
#
# Instead, there is a ActsAsXapianJob model which stores which models need
# updating or deleting in the search index. A rake task 'xapian:update_index'
# then performs the updates since last change. Run it on a cron job, or
# similar.
#
# Email francis@mysociety.org with patches.
#
#
# Comparison to acts_as_solr (as on 24 April 2008)
# ==========================
#
# * Offline indexing only mode - which is a minus if you want changes
# immediately reflected in the search index, and a plus if you were going to
# have to implement your own offline indexing anyway.
#
# * Collapsing - the equivalent of SQL's "group by". You can specify a field
# to collapse on, and only the most relevant result from each value of that
# field is returned. Along with a count of how many there are in total.
# acts_as_solr doesn't have this.
#
# * No highlighting - Xapian can't return you text highlighted with a search query.
# You can try and make do with TextHelper::highlight. I found the highlighting
# in acts_as_solr didn't really understand the query anyway.
#
# * Date range searching - maybe this works in acts_as_solr, but I never found
# out how.
#
# * Spelling correction - "did you mean?" built in and just works.
#
# * Multiple models - acts_as_xapian searches multiple models if you like,
# returning them mixed up together by relevancy. This is like multi_solr_search,
# only it is the default mode of operation and is properly supported.
#
# * No daemons - However, if you have more than one web server, you'll need to
# work out how to use Xapian's remote backend http://xapian.org/docs/remote.html. 
#
# * One layer - full-powered Xapian is called directly from the Ruby, without
# Solr getting in the way whenever you want to use a new feature from Lucene.
#
# * No Java - an advantage if you're more used to working in the rest of the
# open source world. acts_as_xapian, it's pure Ruby and C++.
#
# * Xapian's awesome email list - the kids over at xapian-discuss are super
# helpful. Useful if you need to extend and improve acts_as_xapian. The
# Ruby bindings are mature and well maintained as part of Xapian.
# http://lists.xapian.org/mailman/listinfo/xapian-discuss
#
#
# Indexing
# ========
#
# 1. Put acts_as_xapian in your models that need search indexing.
#
# e.g. acts_as_xapian :texts => [ :name, :short_name ],
#        :values => [ [ :created_at, 0, "created_at", :date ] ],
#        :terms => [ [ :variety, 'V', "variety" ] ]
#
# Options must include:
# :texts, an array of fields for indexing with full text search 
#         e.g. :texts => [ :title, :body ]
# :values, things which have a range of values for indexing, or for collapsing. 
#         Specify an array quadruple of [ field, identifier, prefix, type ] where 
#         - number is an arbitary numeric identifier for use in the Xapian database
#         - prefix is the part to use in search queries that goes before the :
#         - type can be any of :string, :number or :date
#         e.g. :values => [ [ :created_at, 0, "created_at" ], [ :size, 1, "size"] ]
# :terms, things which come after a : in search queries. Specify an array
#         triple of [ field, char, prefix ] where 
#         - char is an arbitary single upper case char used in the Xapian database
#         - prefix is the part to use in search queries that goes before the :
#         e.g. :terms => [ [ :variety, 'V', "variety" ] ]
# A 'field' is a symbol referring to either an attribute or a function which
# returns the text, date or number to index. Both 'number' and 'char' must be
# the same for the same prefix in different models.
#
# Options may include:
# :eager_load, added as an :include clause when looking up search results in
# database
# :if, either an attribute or a function which if returns false means the
# object isn't indexed
#
# 2. Make and run the migration to create the ActsAsXapianJob model, code below
# (search for ActsAsXapianJob).
#
# 3. Call 'rake xapian::rebuild_index models="ModelName1 ModelName2"' to build the index
# the first time (you must specify all your indexed models). It's put in a
# development/test/production dir in acts_as_xapian/xapiandbs.
#
# 4. Then from a cron job or a daemon, or by hand regularly!, call 'rake xapian:update_index'
#
#
# Querying
# ========
#
# If you just want to test indexing is working, you'll find this rake task
# useful (it has more options, see lib/tasks/xapian.rake)
#   rake xapian:query models="PublicBody User" query="moo"
#
# To perform a query call ActsAsXapian::Search.new. This takes in turn:
#   model_classes - list of models to search, e.g. [PublicBody, InfoRequestEvent]
#   query_string - Google like syntax, see below
# And then a hash of options:
#   :offset - Offset of first result
#   :limit - Number of results per page
#   :sort_by_prefix - Optionally, prefix of value to sort by, otherwise sort by relevance
#   :collapse_by_prefix - Optionally, prefix of value to collapse by (i.e. only return most relevant result from group)
#
# Google like query syntax is as described in http://www.xapian.org/docs/queryparser.html
# Queries can include prefix:value parts, according to what you indexed in the
# acts_as_xapian part above. You can also say things like model:InfoRequestEvent 
# to constrain by model in more complex ways than the :model parameter, or
# modelid:InfoRequestEvent-100 to only find one specific object.
#
# Returns an ActsAsXapian::Search object. Useful methods are:
#   description - a techy one, to check how the query has been parsed
#   matches_estimated - a guesstimate at the total number of hits
#   spelling_correction - the corrected query string if there is a correction, otherwise nil
#   results - an array of hashes containing:
#       :model - your Rails model, this is what you most want!
#       :weight - relevancy measure
#       :percent - the weight as a %, 0 meaning the item did not match the query at all
#       :collapse_count - number of results with the same prefix, if you specified collapse_by_prefix

require 'xapian'

module ActsAsXapian
    ######################################################################
    # Module level variables
    # XXX must be some kind of cattr_accessor that can do this better
    def ActsAsXapian.db_path
        @@db_path
    end
    @@db = nil
    def ActsAsXapian.db
        @@db
    end
    @@writable_db = nil
    def ActsAsXapian.writable_db
        @@writable_db
    end
    def ActsAsXapian.stemmer
        @@stemmer
    end
    def ActsAsXapian.term_generator
        @@term_generator
    end
    def ActsAsXapian.enquire
        @@enquire
    end
    def ActsAsXapian.query_parser
        @@query_parser
    end
    def ActsAsXapian.values_by_prefix
        @@values_by_prefix
    end

    ######################################################################
    # Initialisation
    def ActsAsXapian.init(classname, options)
        if @@db.nil?
            # make the directory for the xapian databases to go in
            db_parent_path = File.join(File.dirname(__FILE__), '../xapiandbs/')
            Dir.mkdir(db_parent_path) unless File.exists?(db_parent_path)

            # basic Xapian objects
            @@db_path = File.join(db_parent_path, ENV['RAILS_ENV']) 
            @@db = Xapian::Database.new(@@db_path)
            @@stemmer = Xapian::Stem.new('english')

            # for queries
            @@enquire = Xapian::Enquire.new(@@db)
            @@query_parser = Xapian::QueryParser.new
            @@query_parser.stemmer = @@stemmer
            @@query_parser.stemming_strategy = Xapian::QueryParser::STEM_SOME
            @@query_parser.database = @@db
            @@query_parser.default_op = Xapian::Query::OP_AND

            @@terms_by_capital = {}
            @@values_by_number = {}
            @@values_by_prefix = {}
        end

        # go through the various field types, and tell query parser about them,
        # and error check them - i.e. check for consistency between models
        @@query_parser.add_boolean_prefix("model", "M")
        @@query_parser.add_boolean_prefix("modelid", "I")
        for term in options[:terms]
            raise "Use a single capital letter for term code" if not term[1].match(/^[A-Z]$/)
            raise "M and I are reserved for use as the model/id term" if term[1] == "M" or term[1] == "I"
            raise "model and modelid are reserved for use as the model/id prefixes" if term[2] == "model" or term[2] == "modelid"
            raise "Z is reserved for stemming terms" if term[1] == "Z"
            raise "Already have code '" + term[1] + "' in another model but with different prefix '" + @@terms_by_capital[term[1]] + "'" if @@terms_by_capital.include?(term[1]) && @@terms_by_capital[term[1]] != term[2]
            @@terms_by_capital[term[1]] = term[2]
            @@query_parser.add_boolean_prefix(term[2], term[1])
        end
        for value in options[:values]
            raise "Value index '"+value[1].to_s+"' must be an integer, is " + value[1].class.to_s if value[1].class != 1.class
            raise "Already have value index '" + value[1].to_s + "' in another model but with different prefix '" + @@values_by_number[value[1]].to_s + "'" if @@values_by_number.include?(value[1]) && @@values_by_number[value[1]] != value[2]

            # date types are special, mark them so the first model they're seen for
            if !@@values_by_number.include?(value[1])
                if value[3] == :date 
                    value_range = Xapian::DateValueRangeProcessor.new(value[1])
                elsif value[3] == :string 
                    value_range = Xapian::StringValueRangeProcessor.new(value[1])
                elsif value[3] == :number
                    value_range = Xapian::NumberValueRangeProcessor.new(value[1])
                else
                    raise "Unknown value type '" + value[3].to_s + "'"
                end

                @@query_parser.add_valuerangeprocessor(value_range)
            end

            @@values_by_number[value[1]] = value[2]
            @@values_by_prefix[value[2]] = value[1]

        end
    end

    def ActsAsXapian.writable_init(suffix = "")
        if @@writable_db.nil?
            # for indexing
            @@writable_db = Xapian::WritableDatabase.new(@@db_path + suffix, Xapian::DB_CREATE_OR_OPEN)
            @@term_generator = Xapian::TermGenerator.new()
            @@term_generator.set_flags(Xapian::TermGenerator::FLAG_SPELLING, 0)
            @@term_generator.database = @@writable_db
            @@term_generator.stemmer = @@stemmer
        end
    end

    ######################################################################
    # Search
    
    # Search for a query string, returns an array of hashes in result order.
    # Each hash contains the actual Rails object in :model, and other detail
    # about relevancy etc. in other keys.
    class Search
        attr_accessor :query_string
        attr_accessor :offset
        attr_accessor :limit
        attr_accessor :query
        attr_accessor :matches

        # Note that model_classes is not only sometimes useful here - it's essential to make sure the
        # classes have been loaded, and thus acts_as_xapian called on them, so
        # we know the fields for the query parser.
        def initialize(model_classes, query_string, options = {})
            offset = options[:offset].to_i || 0
            limit = options[:limit].to_i || 10
            sort_by_prefix = options[:sort_by_prefix] || nil
            collapse_by_prefix = options[:collapse_by_prefix] || nil

            if ActsAsXapian.db.nil?
                raise "ActsAsXapian not initialized"
            end

            # Construct query which only finds things from specified models
            model_query = Xapian::Query.new(Xapian::Query::OP_OR, model_classes.map{|mc| "M" + mc.to_s})
            user_query = ActsAsXapian.query_parser.parse_query(query_string,
                  Xapian::QueryParser::FLAG_BOOLEAN | Xapian::QueryParser::FLAG_PHRASE |
                  Xapian::QueryParser::FLAG_LOVEHATE | Xapian::QueryParser::FLAG_WILDCARD |
                  Xapian::QueryParser::FLAG_SPELLING_CORRECTION)
            self.query = Xapian::Query.new(Xapian::Query::OP_AND, model_query, user_query)
            ActsAsXapian.enquire.query = self.query

            if not sort_by_prefix.nil?
                enquire.sort_by_value(ActsAsXapian.values_by_prefix[sort_by_prefix])
            end
            if not collapse_by_prefix.nil?
                enquire.set_collapse_key(ActsAsXapian.values_by_prefix[collapse_by_prefix])
            end

            self.matches = ActsAsXapian.enquire.mset(offset, limit, 100)
        end

        # Return a description of the query
        def description
            self.query.description
        end

        # Estimate total number of results
        def matches_estimated
            self.matches.matches_estimated
        end

        # Return query string with spelling correction
        def spelling_correction
            correction = ActsAsXapian.query_parser.get_corrected_query_string
            if correction.empty?
                return nil
            end
            return correction
        end

        # Return array of models found
        def results
            # Pull out all the results
            docs = []
            iter = self.matches._begin
            while not iter.equals(self.matches._end)
                docs.push({:data => iter.document.data, 
                        :percent => iter.percent, 
                        :weight => iter.weight,
                        :collapse_count => iter.collapse_count})
                iter.next
            end

            # Look up without too many SQL queries
            lhash = {}
            lhash.default = []
            for doc in docs
                k = doc[:data].split('-')
                lhash[k[0]] = lhash[k[0]] + [k[1]]
            end
            # for each class, look up all ids
            chash = {}
            for cls, ids in lhash
                conditions = [ "#{cls.constantize.table_name}.id in (?)", ids ]
                found = cls.constantize.find(:all, :conditions => conditions, :include => cls.constantize.xapian_options[:eager_load])
                for f in found
                    chash[[cls, f.id]] = f
                end
            end
            # now get them in right order again
            results = []
            docs.each{|doc| k = doc[:data].split('-'); results << { :model => chash[[k[0], k[1].to_i]],
                    :percent => doc[:percent], :weight => doc[:weight], :collapse_count => doc[:collapse_count] } }
            return results
        end
    end

    ######################################################################
    # Index
   
    # Offline indexing job queue model, create with this migration:
    #    class ActsAsXapianMigration < ActiveRecord::Migration
    #        def self.up
    #           create_table :acts_as_xapian_jobs do |t|
    #                t.column :model, :string, :null => false
    #                t.column :model_id, :integer, :null => false
    #
    #                t.column :action, :string, :null => false
    #            end
    #            add_index :acts_as_xapian_jobs, [:model, :model_id], :unique => true
    #        end
    #
    #        def self.down
    #            remove_table :acts_as_xapian_jobs
    #        end
    #    end
    class ActsAsXapianJob < ActiveRecord::Base
    end

    # Update index with any changes needed, call this offline. Only call it
    # from a script that exits - otherwise Xapian's writable database won't
    # flush your changes. Specifying flush will reduce performance, but 
    # make sure that each index update is definitely saved to disk before
    # logging in the database that it has been.
    def ActsAsXapian.update_index(flush = false)
        ids_to_refresh = ActsAsXapianJob.find(:all).map() { |i| i.id }
        for id in ids_to_refresh
            ActiveRecord::Base.transaction do
                job = ActsAsXapianJob.find(id, :lock =>true)
                # XXX Index functions may reference other models, so we could eager load here too?
                model = job.model.constantize.find(job.model_id) # :include => cls.constantize.xapian_options[:include]
                if job.action == 'update'
                    model.xapian_index
                elsif job.action == 'destroy'
                    model.xapian_destroy
                else
                    raise "unknown ActsAsXapianJob action '" + job.action + "'"
                end
                job.destroy

                if flush
                    ActsAsXapian.writable_db.flush
                end
            end
        end
    end
        
    # You must specify *all* the models here, this totally rebuilds the Xapian database.
    # You'll want any readers to reopen the database after this.
    def ActsAsXapian.rebuild_index(model_classes)
        raise "when rebuilding all, please call as first and only thing done in process / task" if not ActsAsXapian.writable_db.nil?

        # Delete any existing .new database, and open a new one
        new_path = ActsAsXapian.db_path + ".new"
        if File.exist?(new_path)
            raise "found existing " + new_path + " which is not Xapian flint database, please delete for me" if not File.exist?(File.join(new_path, "iamflint"))
            FileUtils.rm_rf(new_path)
        end
        ActsAsXapian.writable_init(".new")

        # Index everything 
        ActsAsXapianJob.destroy_all
        for model_class in model_classes
            models = model_class.find(:all)
            for model in models
                model.xapian_index
            end
        end
        ActsAsXapian.writable_db.flush

        # Rename into place
        old_path = ActsAsXapian.db_path
        temp_path = ActsAsXapian.db_path + ".tmp"
        if File.exist?(temp_path)
            raise "temporary database found " + temp_path + " which is not Xapian flint database, please delete for me" if not File.exist?(File.join(temp_path, "iamflint"))
            FileUtils.rm_rf(temp_path)
        end
        FileUtils.mv old_path, temp_path
        FileUtils.mv new_path, old_path

        # Delete old database
        if File.exist?(temp_path)
            raise "old database now at " + temp_path + " is not Xapian flint database, please delete for me" if not File.exist?(File.join(temp_path, "iamflint"))
            FileUtils.rm_rf(temp_path)
        end

        # You'll want to restart your FastCGI or Mongrel processes after this,
        # so they get the new db
    end

    ######################################################################
    # Instance methods that get injected into your model.
    
    module InstanceMethods
        # Extract value of a field from the model
        def xapian_value(field, type = nil)
            value = self[field] || self.instance_variable_get("@#{field.to_s}".to_sym) || self.send(field.to_sym)
            if type == :date
                value.utc.strftime("%Y%m%d")
            elsif type == :boolean
                value ? true : false
            else
                value.to_s
            end
        end

        # Store record in the Xapian database
        def xapian_index
            # if we have a conditional function for indexing, call it and destory object if failed
            if self.class.xapian_options.include?(:if)
                if_value = xapian_value(self.class.xapian_options[:if], :boolean)
                if not if_value
                    self.xapian_destroy
                    return
                end
            end

            # otherwise (re)write the Xapian record for the object
            ActsAsXapian.writable_init

            doc = Xapian::Document.new
            ActsAsXapian.term_generator.document = doc

            doc.data = self.class.to_s + "-" + self.id.to_s

            doc.add_term("M" + self.class.to_s)
            doc.add_term("I" + doc.data)
            for term in xapian_options[:terms]
                doc.add_term(term[1] + xapian_value(term[0]))
            end
            for value in xapian_options[:values]
                doc.add_value(value[1], xapian_value(value[0], value[3])) 
            end
            for text in xapian_options[:texts]
                ActsAsXapian.term_generator.increase_termpos # stop phrases spanning different text fields
                ActsAsXapian.term_generator.index_text(xapian_value(text)) 
            end

            ActsAsXapian.writable_db.replace_document("I" + doc.data, doc)
        end

        # Delete record from the Xapian database
        def xapian_destroy
            ActsAsXapian.writable_init

            ActsAsXapian.writable_db.delete_document("I" + self.class.to_s + "-" + self.id.to_s)
        end

        # Used to mark changes needed by batch indexer
        def xapian_mark_needs_index
            model = self.class.to_s
            model_id = self.id
            ActiveRecord::Base.transaction do
                found = ActsAsXapianJob.delete_all([ "model = ? and model_id = ?", model, model_id])
                job = ActsAsXapianJob.new
                job.model = model
                job.model_id = model_id
                job.action = 'update'
                job.save!
            end
        end
        def xapian_mark_needs_destroy
            model = self.class.to_s
            model_id = self.id
            ActiveRecord::Base.transaction do
                found = ActsAsXapianJob.delete_all([ "model = ? and model_id = ?", model, model_id])
                job = ActsAsXapianJob.new
                job.model = model
                job.model_id = model_id
                job.action = 'destroy'
                job.save!
            end
        end
     end

    ######################################################################
    # Main entry point, add acts_as_xapian to your model.
    
    module ActsMethods
        # See top of this file for docs
        def acts_as_xapian(options)
            include InstanceMethods

            cattr_accessor :xapian_options
            self.xapian_options = options

            ActsAsXapian.init(self.class.to_s, options)

            after_save :xapian_mark_needs_index
            after_destroy :xapian_mark_needs_destroy
        end
    end
   
end

# Reopen ActiveRecord and include the acts_as_xapian method
ActiveRecord::Base.extend ActsAsXapian::ActsMethods


