# acts_as_xapian/lib/acts_as_xapian.rb:
# Xapian search in Ruby on Rails.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: acts_as_xapian.rb,v 1.2 2008-04-23 14:58:11 francis Exp $

# TODO:
# Cope with making acts_as_xapian get called before search by preloading classes somewhere
# Make all indexing offline - have a table where what needs doing is stored

# Spell checking

# Query just one model type
# Eager loading
# Boost particular fields?

require 'xapian'

module ActsAsXapian
    # Module level variables
    # XXX must be some kind of cattr_accessor that can do this better
    def ActsAsXapian.db_path
        @@db_path
    end
    @@db = nil
    def ActsAsXapian.db
        @@db
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
    def ActsAsXapian.init(classname, options)
        if @@db.nil?
            # make the directory for the xapian databases to go in
            db_parent_path = File.join(File.dirname(__FILE__), '../xapiandbs/')
            Dir.mkdir(db_parent_path) unless File.exists?(db_parent_path)

            # basic Xapian objects
            @@db_path = File.join(db_parent_path, ENV['RAILS_ENV']) 
            @@db = Xapian::WritableDatabase.new(@@db_path, Xapian::DB_CREATE_OR_OPEN)
            @@stemmer = Xapian::Stem.new('english')
            
            # for indexing
            @@term_generator = Xapian::TermGenerator.new()
            @@term_generator.set_flags(Xapian::TermGenerator::FLAG_SPELLING, 0)
            @@term_generator.database = @@db
            @@term_generator.stemmer = @@stemmer

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
        for term in options[:terms]
            raise "Use a single capital letter for term code" if not term[1].match(/^[A-Z]$/)
            raise "M and I are reserved for use as the model/id term" if term[1] == "M" or term[1] == "I"
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

    # Search for a query string, returns an array of hashes in result order.
    # Each hash contains the actual Rails object in :model, and other detail
    # about relevancy etc. in other keys.
    class Search
        attr_accessor :query_string
        attr_accessor :first_result
        attr_accessor :results_per_page
        attr_accessor :query
        attr_accessor :matches

        def initialize(query_string, first_result, results_per_page, sort_by_prefix = nil, collapse_by_prefix = nil)
            self.query = ActsAsXapian.query_parser.parse_query(query_string,
                  Xapian::QueryParser::FLAG_BOOLEAN | Xapian::QueryParser::FLAG_PHRASE |
                  Xapian::QueryParser::FLAG_LOVEHATE | Xapian::QueryParser::FLAG_WILDCARD |
                  Xapian::QueryParser::FLAG_SPELLING_CORRECTION)
            ActsAsXapian.enquire.query = self.query

            if not sort_by_prefix.nil?
                enquire->sort_by_value(ActsAsXapian.values_by_prefix[sort_by_prefix])
            end
            if not collapse_by_prefix.nil?
                enquire->set_collapse_key(ActsAsXapian.values_by_prefix[collapse_by_prefix])
            end

            self.matches = ActsAsXapian.enquire.mset(first_result, results_per_page, 100)
        end

        # Return a description of the query
        def techy_description
            self.query.description
        end

        # Estimate total number of results
        def count
            self.matches.matches_estimated
        end

        # Return array of models found
        # XXX currently only returns all types of models
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
                # XXX add eager loading in line below: :include => options[:include][cls.to_sym])
                found = cls.constantize.find(:all, :conditions => conditions, :include => nil)
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

    # Functions that are called after saving or deleting a model, which update the Xapian database
    module InstanceMethods
        # Extract value of a field from the model
        def xapian_value(field, type = nil)
            value = self[field] || self.instance_variable_get("@#{field.to_s}".to_sym) || self.send(field.to_sym)
            if type == :date
                value.utc.strftime("%Y%m%d")
            else
                value.to_s
            end
        end

        # Store record in the Xapian database
        def xapian_save
            ActsAsXapian.db.begin_transaction # XXX hoping this will lock/unlock on disk too?

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

            ActsAsXapian.db.replace_document("I" + doc.data, doc)
            ActsAsXapian.db.commit_transaction 
        end

        # Delete record from the Xapian database
        def xapian_destroy
            raise "xapian_destroy"
        end
    end

    # Main entry point
    module ActsMethods

        # Put acts_as_xapian in your models that need search indexing.
        #
        # Options must include:
        # :texts, an array of fields for indexing with full text search 
        #         e.g. :texts => [ :title, :body ]
        # :values, things which have a range of values for indexing, or for collapsing. 
        #         Specify an array quadruple of [ field, index, prefix, type ] where 
        #         - :index is an arbitary numeric identifier for use in the Xapian database
        #         - :prefix is the part to use in search queries that goes before the :
        #         - :type can be any of :string, :number or :date
        #         e.g. :values => [ [ :created_at, 0, "created_at" ], [ :size, 1, "size"] ]
        # :terms, things which come after a : in search queries. Specify an array
        #         triple of [ field, char, prefix ] where 
        #         - :char is an arbitary single upper case char used in the Xapian database
        #         - :prefix is the part to use in search queries that goes before the :
        #         e.g. :terms => [ [ :variety, 'V', "variety" ] ]
        # A field is a symbol referring to either an attribute or a name
        def acts_as_xapian(options)
            include InstanceMethods

            cattr_accessor :xapian_options
            self.xapian_options = options

            ActsAsXapian.init(self.class.to_s, options)

            after_save :xapian_save
            after_destroy :xapian_destroy
        end
    end
   
end

# Reopen ActiveRecord and include the acts_as_xapian method
ActiveRecord::Base.extend ActsAsXapian::ActsMethods


