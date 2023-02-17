# acts_as_xapian/lib/acts_as_xapian.rb:
# Xapian full text search in Ruby on Rails.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/
#
# Documentation
# =============
#
# See ../README.txt foocumentation. Please update that file if you edit
# code.

# Make it so if Xapian isn't installed, the Rails app doesn't fail completely,
# just when somebody does a search.
begin
  require 'xapian'
  $acts_as_xapian_bindings_available = true
rescue LoadError
  STDERR.puts "acts_as_xapian: No Ruby bindings for Xapian installed"
  $acts_as_xapian_bindings_available = false
end

module Xapian
  class QueryParser
    unless method_defined?(:unstem)
      def unstem(term)
        words = []

        Xapian._safelyIterate(unstem_begin(term), unstem_end(term)) do |item|
          words << item.term
        end

        words
      end
    end
  end
end

module ActsAsXapian
  ######################################################################
  # Module level variables
  # TODO: must be some kind of cattr_accessor that can do this better
  def self.bindings_available
    $acts_as_xapian_bindings_available
  end
  NoXapianRubyBindingsError = Class.new(StandardError)
  UnhandledRuntimeError = Class.new(StandardError)

  @@db = nil
  @@db_path = nil
  @@writable_db = nil
  @@init_values = []

  # There used to be a problem with this module being loaded more than once.
  # Keep a check here, so we can tell if the problem recurs.
  if $acts_as_xapian_class_var_init
    raise "The acts_as_xapian module has already been loaded"
  else
    $acts_as_xapian_class_var_init = true
  end

  def self.db
    @@db
  end
  def self.db_path=(db_path)
    @@db_path = db_path
  end
  def self.db_path
    @@db_path
  end
  def self.writable_db
    @@writable_db
  end
  def self.stemmer
    @@stemmer
  end
  def self.term_generator
    @@term_generator
  end
  def self.enquire
    @@enquire
  end
  def self.query_parser
    @@query_parser
  end
  def self.values_by_prefix
    @@values_by_prefix
  end
  def self.config
    @@config
  end
  def self.max_wildcard_expansion=(max_wildcard_expansion)
    @@max_wildcard_expansion = max_wildcard_expansion
  end
  def self.max_wildcard_expansion
    @@max_wildcard_expansion
  end

  ######################################################################
  # Initialisation
  def self.init(classname = nil, options = nil)
    unless classname.nil?
      # store class and options for use later, when we open the db in readable_init
      @@init_values.push([classname,options])
    end
  end

  # Reads the config file (if any) and sets up the path to the database we'll be using
  def self.prepare_environment
    return unless @@db_path.nil?

    # barf if we can't figure out the environment
    environment = (ENV['RAILS_ENV'] or Rails.env)
    unless environment
      raise "Set RAILS_ENV, so acts_as_xapian can find the right Xapian database"
    end

    # check for a config file
    config_file = Rails.root.join("config","xapian.yml")
    @@config = YAML.load_file(config_file)[environment] if config_file.exist?
    @@config ||= {}

    # figure out where the DBs should go
    if config['base_db_path']
      db_parent_path = Rails.root.join(config['base_db_path'])
    else
      db_parent_path = File.join(File.dirname(__FILE__), 'xapiandbs')
    end

    # make the directory for the xapian databases to go in
    Dir.mkdir(db_parent_path) unless File.exist?(db_parent_path)

    @@db_path = File.join(db_parent_path, environment)

    @@max_wildcard_expansion = config.fetch('max_wildcard_expansion', 1000)

    # make some things that don't depend on the db
    # TODO: this gets made once for each acts_as_xapian. Oh well.
    @@stemmer = Xapian::Stem.new('english')
  end

  # Opens / reopens the db for reading
  # TODO: we perhaps don't need to rebuild database and enquire and queryparser -
  # but db.reopen wasn't enough by itself, so just do everything it's easier.
  def self.readable_init
    unless ActsAsXapian.bindings_available
      raise NoXapianRubyBindingsError.new("Xapian Ruby bindings not installed")
    end
    if @@init_values.empty?
      raise "acts_as_xapian hasn't been called in any models"
    end

    prepare_environment

    # We need to reopen the database each time, so Xapian gets changes to it.
    # Calling reopen does not always pick up changes for reasons that I can
    # only speculate about at the moment. (It is easy to reproduce this by
    # changing the code below to use reopen rather than open followed by
    # close, and running rake spec.)
    @@db.close unless @@db.nil?

    # basic Xapian objects
    begin
      @@db = Xapian::Database.new(@@db_path)
      @@enquire = Xapian::Enquire.new(@@db)
    rescue IOError => e
      raise "Failed to open Xapian database #{@@db_path}: #{e.message}"
    end

    init_query_parser
  end

  # Make a new query parser
  def self.init_query_parser
    # for queries
    @@query_parser = Xapian::QueryParser.new
    @@query_parser.stemmer = @@stemmer
    @@query_parser.stemming_strategy = Xapian::QueryParser::STEM_SOME
    @@query_parser.database = @@db
    @@query_parser.default_op = Xapian::Query::OP_AND
    # The set_max_wildcard_expansion method was introduced in Xapian 1.2.7,
    # so may legitimately not be available.
    #
    # Large installations of Alaveteli should consider
    # upgrading, because uncontrolled wildcard expansion
    # can crash the whole server: see http://trac.xapian.org/ticket/350
    if @@query_parser.respond_to? :set_max_wildcard_expansion
      @@query_parser.set_max_wildcard_expansion(@@max_wildcard_expansion)
    end

    @@stopper = Xapian::SimpleStopper.new
    @@stopper.add("and")
    @@stopper.add("of")
    @@stopper.add("&")
    @@query_parser.stopper = @@stopper

    @@terms_by_capital = {}
    @@values_by_number = {}
    @@values_by_prefix = {}
    @@value_ranges_store = []

    @@init_values.each do |classname, options|
      # go through the various field types, and tell query parser about them,
      # and error check them - i.e. check for consistency between models
      @@query_parser.add_boolean_prefix("model", "M")
      @@query_parser.add_boolean_prefix("modelid", "I")
      init_terms(options[:terms]) if options[:terms]
      init_values(options[:values]) if options[:values]
    end
  end

  def self.init_values(values)
    values.each do |method, index, prefix, value_type|
      unless index.is_a? Integer
        raise "Value index '#{index}' must be an Integer, is #{index.class}"
      end
      if @@values_by_number.include?(index) && @@values_by_number[index] != prefix
        raise "Already have value index '#{index}' in another model " \
          "but with different prefix '#{@@values_by_number[index]}'"
      end
      # date types are special, mark them so the first model they're seen for
      unless @@values_by_number.include?(index)
        case value_type
        when :date
          value_range = Xapian::DateValueRangeProcessor.new(index)
        when :string
          value_range = Xapian::StringValueRangeProcessor.new(index)
        when :number
          value_range = Xapian::NumberValueRangeProcessor.new(index)
        else
          raise "Unknown value type '#{value_type}'"
        end

        @@query_parser.add_valuerangeprocessor(value_range)

        # stop it being garbage collected, as
        # add_valuerangeprocessor ref is outside Ruby's GC
        @@value_ranges_store.push(value_range)
      end

      @@values_by_number[index] = prefix
      @@values_by_prefix[prefix] = index
    end
  end

  def self.init_terms(terms)
    terms.each do |method, term_code, prefix|
      unless term_code.match(/^[A-Z]$/)
        raise "Use a single capital letter for term code"
      end
      if term_code == "M" || term_code == "I"
        raise "M and I are reserved for use as the model/id term"
      end
      if prefix == "model" || prefix == "modelid"
        raise "model and modelid are reserved for use as the model/id prefixes"
      end
      raise "Z is reserved for stemming terms" if term_code == "Z"
      if @@terms_by_capital.include?(term_code) && @@terms_by_capital[term_code] != prefix
        raise "Already have code '#{term_code}' in another model but with different prefix " \
          "'#{@@terms_by_capital[term_code]}'"
      end
      @@terms_by_capital[term_code] = prefix
      # TODO: use boolean here so doesn't stem our URL names in WhatDoTheyKnow
      # If making acts_as_xapian generic, would really need to make the :terms have
      # another option that lets people choose non-boolean for terms that need it
      # (i.e. searching explicitly within a free text field)
      @@query_parser.add_boolean_prefix(prefix, term_code)
    end
  end

  def self.writable_init(suffix = "")
    unless ActsAsXapian.bindings_available
      raise NoXapianRubyBindingsError.new("Xapian Ruby bindings not installed")
    end
    if @@init_values.empty?
      raise "acts_as_xapian hasn't been called in any models"
    end

    # if DB is not nil, then we're already initialised, so don't do it
    # again TODO: reopen it each time, xapian_spec.rb needs this so database
    # gets written twice correctly.
    # return unless @@writable_db.nil?

    prepare_environment

    full_path = @@db_path + suffix

    # for indexing
    @@writable_db = Xapian::WritableDatabase.new(full_path, Xapian::DB_CREATE_OR_OPEN | _xapian_backend_format(full_path))
    @@enquire = Xapian::Enquire.new(@@writable_db)
    @@term_generator = Xapian::TermGenerator.new
    @@term_generator.set_flags(Xapian::TermGenerator::FLAG_SPELLING, 0)
    @@term_generator.database = @@writable_db
    @@term_generator.stemmer = @@stemmer
  end

  ######################################################################
  # Search with a query or for similar models

  # Base class for Search and Similar below
  class QueryBase
    attr_accessor :offset
    attr_accessor :limit
    attr_accessor :query
    attr_accessor :matches
    attr_accessor :query_models
    attr_accessor :runtime
    attr_accessor :cached_results

    def initialize_db
      self.runtime = 0.0

      ActsAsXapian.readable_init
      raise "ActsAsXapian not initialized" if ActsAsXapian.db.nil?
    end

    MSET_MAX_TRIES = 5
    MSET_MAX_DELAY = 5
    # Set self.query before calling this
    def initialize_query(options)
      #raise options.to_yaml

      self.runtime += Benchmark::realtime {
        offset = options[:offset] || 0; offset = offset.to_i
        limit = options[:limit]
        unless limit
          raise "please specifiy maximum number of results to return with parameter :limit"
        end
        limit = limit.to_i
        sort_by_prefix = options[:sort_by_prefix] || nil
        sort_by_ascending = options[:sort_by_ascending].nil? ? true : options[:sort_by_ascending]
        collapse_by_prefix = options[:collapse_by_prefix] || nil

        ActsAsXapian.enquire.query = query

        if sort_by_prefix.nil?
          ActsAsXapian.enquire.sort_by_relevance!
        else
          value = ActsAsXapian.values_by_prefix[sort_by_prefix]
          if value.nil?
            raise "couldn't find prefix '" + sort_by_prefix.to_s + "'"
          end
          ActsAsXapian.enquire.sort_by_value_then_relevance!(value, sort_by_ascending)
        end
        if collapse_by_prefix.nil?
          ActsAsXapian.enquire.collapse_key = Xapian::BAD_VALUENO
        else
          value = ActsAsXapian.values_by_prefix[collapse_by_prefix]
          if value.nil?
            raise "couldn't find prefix '" + collapse_by_prefix + "'"
          end
          ActsAsXapian.enquire.collapse_key = value
        end

        tries = 0
        delay = 1
        begin
          self.matches = ActsAsXapian.enquire.mset(offset, limit, 100)
        rescue IOError => e
          if e.message =~ /DatabaseModifiedError: /
            # This should be a transient error, so back off and try again, up to a point
            if tries > MSET_MAX_TRIES
              raise "Received DatabaseModifiedError from Xapian even after retrying #{MSET_MAX_TRIES} times"
            else
              sleep delay
            end
            tries += 1
            delay *= 2
            delay = MSET_MAX_DELAY if delay > MSET_MAX_DELAY

            ActsAsXapian.db.reopen
            retry
          else
            raise
          end
        rescue RuntimeError => ex
          raise UnhandledRuntimeError, ex.message
        end
        self.cached_results = nil
      }
    end

    # Return a description of the query
    def description
      query.description
    end

    # Does the query have non-prefixed search terms in it?
    def has_normal_search_terms?
      ret = false
      #x = ''
      for t in query.terms
        term = t.term
        #x = x + term.to_yaml + term.size.to_s + term[0..0] + "*"
        if term.size >= 2 && term[0..0] == 'Z'
          # normal terms begin Z (for stemmed), then have no capital letter prefix
          ret = true if term[1..1] == term[1..1].downcase
        end
      end
      ret
    end

    # Estimate total number of results
    def matches_estimated
      matches.matches_estimated
    end

    # Return query string with spelling correction
    def spelling_correction
      correction = ActsAsXapian.query_parser.get_corrected_query_string
      return nil if correction.empty?
      correction.force_encoding('UTF-8')
    end

    # Return array of models found
    def results
      # If they've already pulled out the results, just return them.
      return cached_results unless cached_results.nil?

      docs = []
      self.runtime += Benchmark::realtime {
        # Pull out all the results
        iter = matches._begin
        while not iter.equals(matches._end)
          docs.push({data: iter.document.data,
                     percent: iter.percent,
                     weight: iter.weight,
                     collapse_count: iter.collapse_count})
          iter.next
        end
      }

      # Log time taken, excluding database lookups below which will be displayed separately by ActiveRecord
      if ActiveRecord::Base.logger
        ActiveRecord::Base.logger.add(Logger::DEBUG, format("  Xapian query (%.5fs) %s", self.runtime, self.log_description))
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
        found = cls.constantize.
          includes(cls.constantize.xapian_options[:eager_load]).
            where("#{cls.constantize.table_name}.#{cls.constantize.primary_key}
                   in (?)", ids)
        for f in found
          chash[[cls, f.id]] = f
        end
      end
      # now get them in right order again
      results = []
      docs.each do |doc|
        k = doc[:data].split('-')
        model_instance = chash[[k[0], k[1].to_i]]
        if model_instance
          results << { model: model_instance,
                       percent: doc[:percent],
                       weight: doc[:weight],
                       collapse_count: doc[:collapse_count] }
        end
      end
      self.cached_results = results
      results
    end
  end

  # Search for a query string, returns an array of hashes in result order.
  # Each hash contains the actual Rails object in :model, and other detail
  # about relevancy etc. in other keys.
  class Search < QueryBase
    attr_accessor :query_string

    # Note that model_classes is not only sometimes useful here - it's
    # essential to make sure the classes have been loaded, and thus
    # acts_as_xapian called on them, so we know the fields for the query
    # parser.

    # model_classes - model classes to search within, e.g. [PublicBody,
    # User]. Can take a single model class, or you can express the model
    # class names in strings if you like.
    # query_string - user inputed query string, with syntax much like Google Search
    def initialize(model_classes, query_string, options = {}, user_query = nil)
      # Check parameters, convert to actual array of model classes
      new_model_classes = []
      model_classes = [model_classes] if model_classes.class != Array
      for model_class in model_classes
        if model_class.class != Class && model_class.class != String
          raise "pass in the model class itself, or a string containing its name"
        end
        model_class = model_class.constantize if model_class.class == String
        new_model_classes.push(model_class)
      end
      model_classes = new_model_classes

      # Set things up
      initialize_db

      # Case of a string, searching for a Google-like syntax query
      self.query_string = query_string

      # Construct query which only finds things from specified models
      model_query = Xapian::Query.new(Xapian::Query::OP_OR, model_classes.map { |mc| "M" + mc.to_s })
      if user_query.nil?
        user_query = ActsAsXapian.query_parser.parse_query(
          self.query_string,
          Xapian::QueryParser::FLAG_BOOLEAN | Xapian::QueryParser::FLAG_PHRASE |
          Xapian::QueryParser::FLAG_LOVEHATE |
          Xapian::QueryParser::FLAG_SPELLING_CORRECTION)
      end
      self.query = Xapian::Query.new(Xapian::Query::OP_AND, model_query, user_query)

      # Call base class constructor
      initialize_query(options)
    end

    # Return just normal words in the query i.e. Not operators, ones in
    # date ranges or similar. Use this for cheap highlighting with
    # TextHelper::highlight, and excerpt.
    def words_to_highlight(opts = {})
      default_opts = { include_original: false, regex: false }
      opts = default_opts.merge(opts)

      # Reject all prefixes other than Z, which we know is reserved for stems
      terms = query.terms.reject { |t| t.term.first.match(/^[A-Y]$/) }
      # Collect the stems including the Z prefix
      raw_stems = terms.map { |t| if t.term.start_with?('Z')
                                    t.term
                                  end }.compact.uniq.sort
      # Collect stems, chopping the Z prefix off
      stems = raw_stems.map { |t| t[1..-1] }.compact.sort
      # Collect the non-stem terms
      words = terms.map { |t| unless t.term.start_with?('Z')
                                t.term
                              end }.compact.sort

      # Add the unstemmed words from the original query
      # Sometimes stems can be unhelpful with the :regex option, for example
      # stemming 'boring' results in us trying to highlight 'bore'.
      if opts[:include_original]
        raw_stems.each do |raw_stem|
          words << ActsAsXapian.query_parser.unstem(raw_stem).uniq
        end

        words = words.any? ? words.flatten.uniq : []
      end

      if opts[:regex]
        stems.map! { |w| /\b(#{ correctly_encode(w) })\w*\b/iu }
        words.map! { |w| /\b(#{ correctly_encode(w) })\b/iu }
      end

      (stems + words).map! do |term|
        term.is_a?(String) ? correctly_encode(term) : term
      end
    end

    # Text for lines in log file
    def log_description
      "Search: " + query_string
    end

    private

    def correctly_encode(w)
      w.force_encoding('UTF-8')
    end

  end

  # Search for models which contain theimportant terms taken from a specified
  # list of models. i.e. Use to find documents similar to one (or more)
  # documents, or use to refine searches.
  class Similar < QueryBase
    attr_accessor :query_models
    attr_accessor :important_terms

    # model_classes - model classes to search within, e.g. [PublicBody, User]
    # query_models - list of models you want to find things similar to
    def initialize(model_classes, query_models, options = {})
      initialize_db

      self.runtime += Benchmark::realtime {
        # Case of an array, searching for models similar to those models in the array
        self.query_models = query_models

        # Find the documents by their unique term
        input_models_query = Xapian::Query.new(Xapian::Query::OP_OR, query_models.map { |m| "I" + m.xapian_document_term })
        ActsAsXapian.enquire.query = input_models_query
        matches = ActsAsXapian.enquire.mset(0, 100, 100) # TODO: so this whole method will only work with 100 docs

        # Get set of relevant terms for those documents
        selection = Xapian::RSet.new
        iter = matches._begin
        while not iter.equals(matches._end)
          selection.add_document(iter)
          iter.next
        end

        # Bit weird that the function to make esets is part of the enquire
        # object. This explains what exactly it does, which is to exclude
        # terms in the existing query.
        # http://thread.gmane.org/gmane.comp.search.xapian.general/3673/focus=3681
        eset = ActsAsXapian.enquire.eset(40, selection)

        # Do main search for them
        self.important_terms = []
        iter = eset._begin
        while not iter.equals(eset._end)
          important_terms.push(iter.term)
          iter.next
        end
        similar_query = Xapian::Query.new(Xapian::Query::OP_OR, important_terms)
        # Exclude original
        combined_query = Xapian::Query.new(Xapian::Query::OP_AND_NOT, similar_query, input_models_query)

        # Restrain to model classes
        model_query = Xapian::Query.new(Xapian::Query::OP_OR, model_classes.map { |mc| "M" + mc.to_s })
        self.query = Xapian::Query.new(Xapian::Query::OP_AND, model_query, combined_query)
      }

      # Call base class constructor
      initialize_query(options)
    end

    # Text for lines in log file
    def log_description
      "Similar: " + query_models.to_s
    end
  end

  ######################################################################
  # Index

  # Offline indexing job queue model, create with migration made
  # using "script/generate acts_as_xapian" as described in ../README.txt
  class ActsAsXapianJob < ActiveRecord::Base
  end

  # Encapsulates an ActsAsXapianJob ID that failed, the error that occured and
  # information about the model that was being indexed in order to print
  # diagnostic information.
  class FailedJob
    attr_reader :job_id, :error, :model_data

    def initialize(job_id, error, model_data = {})
      @job_id = job_id
      @error = error
      @model_data = model_data
    end

    def job_info
      msg = "FAILED ActsAsXapian.update_index job #{ job_id } #{ error.class }"
      msg += " model #{ job_model }" if job_model
      msg += " id #{ job_model_id }" if job_model_id
      msg += '.'
      msg
    end

    # TODO: This tries to call join on nil in Ruby 2.5.0.
    # We think its a Rails 4.2.x + Ruby 2.5.x incompatibility.
    # https://github.com/mysociety/alaveteli/pull/4592#discussion_r180816027
    def error_backtrace
      error.backtrace.join("\n")
    end

    def full_message
      msg = job_info
      msg += "\n\n"
      msg += error_message
      msg += "\n\n"
      msg += retry_message
      msg += "\n\n"
      msg += backtrace_header
      msg += "\n"
      msg += error_backtrace
    end

    private

    def job_model
      model_data[:model]
    end

    def job_model_id
      model_data[:model_id]
    end

    def error_message
      "#{ error.class }: #{ error.message }."
    end

    def retry_message
      msg = 'This job will be removed from the queue. Once the underlying ' \
            'problem is fixed, manually re-index the model record.'

      if job_model && job_model_id
        msg += "\n\n"
        msg += "You can do this in a rails console with " \
               "`#{job_model}.find(#{job_model_id}).xapian_mark_needs_index`."
      end

      msg
    end

    def backtrace_header
      <<-EOF.strip_heredoc
      ---------
      Backtrace
      ---------
      EOF
    end
  end

  # Update index with any changes needed, call this offline. Usually call it
  # from a script that exits - otherwise Xapian's writable database won't
  # flush your changes. Specifying flush will reduce performance, but make
  # sure that each index update is definitely saved to disk before
  # logging in the database that it has been.
  def self.update_index(flush = false, verbose = false)
    # STDOUT.puts("start of ActsAsXapian.update_index") if verbose

    # Before calling writable_init we have to make sure every model class has been initialized.
    # i.e. has had its class code loaded, so acts_as_xapian has been called inside it, and
    # we have the info from acts_as_xapian.
    model_classes = ActsAsXapianJob.distinct.pluck(:model).map { |a| a.constantize }
    # If there are no models in the queue, then nothing to do
    return if model_classes.empty?

    ActsAsXapian.writable_init
    # Abort if full rebuild is going on
    new_path = ActsAsXapian.db_path + ".new"
    if File.exist?(new_path)
      raise "aborting incremental index update while full index rebuild happens; found existing #{new_path}"
    end

    ActsAsXapianJob.order(:created_at).pluck(:id).each do |id|
      job = nil
      begin
        ActiveRecord::Base.transaction do
          begin
            job = ActsAsXapianJob.lock(true).find(id)
          rescue ActiveRecord::RecordNotFound => e
            # This could happen if while we are working the model
            # was updated a second time by another process. In that case
            # ActsAsXapianJob.delete_all in xapian_mark_needs_index below
            # might have removed the first job record while we are working on it.
            #STDERR.puts("job with #{id} vanished under foot") if verbose
            next
          end
          run_job(job, flush, verbose)
        end
      rescue StandardError, NoMemoryError => error
        # print any error, and carry on so other things are indexed
        model_data = { model: job.try(:model), model_id: job.try(:model_id) }
        failed_job = FailedJob.new(id, error, model_data)
        STDERR.puts(failed_job.full_message)
      ensure
        # We never want to reprocess existing jobs.
        # If it succeeded the first time, it should already be destroyed.
        # If it failed, then we don't want to keep trying to process it every
        # cron run – we should create an issue and investigate it, and requeue
        # the record once there's a fix in place.
        job.try(:destroy)
      end
    end
    # We close the database when we're finished to remove the lock file. Since writable_init
    # reopens it and recreates the environment every time we don't need to do further cleanup
    ActsAsXapian.writable_db.flush
    ActsAsXapian.writable_db.close
  end

  def self.run_job(job, flush, verbose)
    if verbose
      STDOUT.puts("ActsAsXapian.update_index #{job.action} #{job.model} #{job.model_id.to_s} #{Time.now.to_s}")
    end

    begin
      if job.action == 'update'
        # TODO: Index functions may reference other models, so we could eager load here too?
        model = job.model.constantize.find(job.model_id) # :include => cls.constantize.xapian_options[:include]
        model.xapian_index
      elsif job.action == 'destroy'
        # Make dummy model with right id, just for destruction
        model = job.model.constantize.new
        model.id = job.model_id
        model.xapian_destroy
      else
        raise "unknown ActsAsXapianJob action '#{job.action}'"
      end
    rescue ActiveRecord::RecordNotFound => e
      # this can happen if the record was hand deleted in the database
      job.action = 'destroy'
      retry
    end
    ActsAsXapian.writable_db.flush if flush
    job.destroy
  end

  def self._is_xapian_chert_db(path)
    File.exist?(File.join(path, "iamchert"))
  end

  def self._is_xapian_glass_db(path)
    File.exist?(File.join(path, "iamglass"))
  end

  def self._is_xapian_db(path)
    _is_xapian_chert_db(path) || _is_xapian_glass_db(path)
  end

  def self._xapian_backend_format(path)
    if _is_xapian_chert_db(path)
      Xapian::DB_BACKEND_CHERT
    else
      Xapian::DB_BACKEND_GLASS
    end
  end

  # You must specify *all* the models here, this totally rebuilds the Xapian
  # database.  You'll want any readers to reopen the database after this.
  #
  # Incremental update_index calls above are suspended while this rebuild
  # happens (i.e. while the .new database is there) - any index update jobs
  # are left in the database, and will run after the rebuild has finished.
  def self.destroy_and_rebuild_index(model_classes, verbose = false, terms = true, values = true, texts = true, safe_rebuild = true)
    #raise "when rebuilding all, please call as first and only thing done in process / task" if not ActsAsXapian.writable_db.nil?
    prepare_environment

    update_existing = !(terms == true && values == true && texts == true)
    # Delete any existing .new database, and open a new one which is a copy of the current one
    new_path = ActsAsXapian.db_path + ".new"
    old_path = ActsAsXapian.db_path
    if File.exist?(new_path)
      unless ActsAsXapian._is_xapian_db(new_path)
        raise "found existing " + new_path + " which is not Xapian chert or glass database, please delete for me"
      end
      FileUtils.rm_r(new_path)
    end
    FileUtils.cp_r(old_path, new_path) if update_existing
    ActsAsXapian.writable_init
    ActsAsXapian.writable_db.close # just to make an empty one to read
    # Index everything
    if safe_rebuild
      _destroy_and_rebuild_index_safely(model_classes, verbose, terms, values, texts)
    else
      @@db_path = ActsAsXapian.db_path + ".new"
      ActsAsXapian.writable_init
      # Save time by running the indexing in one go and in-process
      for model_class in model_classes
        if verbose
          STDOUT.puts("ActsAsXapian.destroy_and_rebuild_index: Rebuilding #{model_class.to_s}")
        end
        model_class.find_each do |model|
          if verbose
            STDOUT.puts("ActsAsXapian.destroy_and_rebuild_index      #{model_class} #{model.id}")
          end
          model.xapian_index(terms, values, texts)
        end
      end
      ActsAsXapian.writable_db.flush
      ActsAsXapian.writable_db.close
    end

    # Rename into place
    temp_path = old_path + ".tmp"
    if File.exist?(temp_path)
      @@db_path = old_path
      unless ActsAsXapian._is_xapian_db(temp_path)
        raise "temporary database found " + temp_path + " which is not Xapian chert or glass database, please delete for me"
      end
      FileUtils.rm_r(temp_path)
    end
    FileUtils.mv old_path, temp_path if File.exist?(old_path)
    FileUtils.mv new_path, old_path

    # Delete old database
    if File.exist?(temp_path)
      unless ActsAsXapian._is_xapian_db(temp_path)
        @@db_path = old_path
        raise "old database now at " + temp_path + " is not Xapian chert or glass database, please delete for me"
      end
      FileUtils.rm_r(temp_path)
    end

    # You'll want to restart your FastCGI or Mongrel processes after this,
    # so they get the new db
    @@db_path = old_path
  end

  def self._destroy_and_rebuild_index_safely(model_classes, verbose, terms, values, texts)
    batch_size = 1000
    for model_class in model_classes
      model_class_count = model_class.count
      0.step(model_class_count, batch_size) do |i|
        # We fork here, so each batch is run in a different process. This is
        # because otherwise we get a memory "leak" and you can't rebuild very
        # large databases (however long you have!)

        ActiveRecord::Base.connection.disconnect!

        pid = Process.fork # TODO: this will only work on Unix, tough
        if pid
          Process.waitpid(pid)
          raise "batch fork child failed, exiting also" unless $?.success?
          # database connection doesn't survive a fork, rebuild it
        else
          # fully reopen the database each time (with a new object)
          # (so doc ids and so on aren't preserved across the fork)
          ActiveRecord::Base.establish_connection
          @@db_path = ActsAsXapian.db_path + ".new"
          ActsAsXapian.writable_init
          if verbose
            STDOUT.puts("ActsAsXapian.destroy_and_rebuild_index: New batch. #{model_class.to_s} from #{i} to #{i + batch_size} of #{model_class_count} pid #{Process.pid.to_s}")
          end
          model_class.limit(batch_size).offset(i).order(:id).each do |model|
            if verbose
              STDOUT.puts("ActsAsXapian.destroy_and_rebuild_index      #{model_class} #{model.id}")
            end
            model.xapian_index(terms, values, texts)
          end
          ActsAsXapian.writable_db.flush
          ActsAsXapian.writable_db.close
          # database connection won't survive a fork, so shut it down
          ActiveRecord::Base.connection.disconnect!
          # brutal exit, so other shutdown code not run (for speed and safety)
          Kernel.exit! 0
        end

        ActiveRecord::Base.establish_connection

      end
    end
  end

  ######################################################################
  # Instance methods that get injected into your model.

  module InstanceMethods
    # Used internally
    def xapian_document_term
      self.class.to_s + "-" + id.to_s
    end

    def xapian_value(field, type = nil, index_translations = false)
      if index_translations && respond_to?("translations")
        if type == :date or type == :boolean
          value = single_xapian_value(field, type = type)
        else
          values = []
          for locale in translations.map { |x| x.locale }
            AlaveteliLocalization.with_locale(locale) do
              values << single_xapian_value(field, type=type)
            end
          end
          if values[0].kind_of?(Array)
            values = values.flatten
            value = values.reject { |x| x.nil? }
          else
            values = values.reject { |x| x.nil? }
            value = values.join(" ")
          end
        end
      else
        value = single_xapian_value(field, type = type)
      end
      value
    end

    # Extract value of a field from the model
    def single_xapian_value(field, type = nil)
      value = send(field.to_sym) || self[field]
      if type == :date
        if value.kind_of?(Time)
          value.utc.strftime("%Y%m%d")
        elsif value.kind_of?(Date)
          value.to_time.utc.strftime("%Y%m%d")
        else
          raise "Only Time or Date types supported by acts_as_xapian for :date fields, got " + value.class.to_s
        end
      elsif type == :boolean
        value ? true : false
      else
        # Arrays are for terms which require multiple of them, e.g. tags
        if value.kind_of?(Array)
          value.map { |v| v.to_s }
        else
          value.to_s
        end
      end
    end

    # Store record in the Xapian database
    def xapian_index(terms = true, values = true, texts = true)
      # if we have a conditional function for indexing, call it and destroy object if failed
      if self.class.xapian_options.include?(:if)
        if_value = xapian_value(self.class.xapian_options[:if], :boolean)
        unless if_value
          xapian_destroy
          return
        end
      end

      existing_query = Xapian::Query.new("I" + xapian_document_term)
      ActsAsXapian.enquire.query = existing_query
      match = ActsAsXapian.enquire.mset(0,1,1).matches[0]

      if !match.nil?
        doc = match.document
      else
        doc = Xapian::Document.new
        doc.data = xapian_document_term
        doc.add_term("M" + self.class.to_s)
        doc.add_term("I" + doc.data)
      end
      # work out what to index
      # 1. Which terms to index?  We allow the user to specify particular ones
      terms_to_index = []
      drop_all_terms = false
      if terms and xapian_options[:terms]
        terms_to_index = xapian_options[:terms].dup
        if terms.is_a?(String)
          terms_to_index.reject! { |term| !terms.include?(term[1]) }
          if terms_to_index.length == xapian_options[:terms].length
            drop_all_terms = true
          end
        else
          drop_all_terms = true
        end
      end
      # 2. Texts to index?  Currently, it's all or nothing
      texts_to_index = []
      if texts and xapian_options[:texts]
        texts_to_index = xapian_options[:texts]
      end
      # 3. Values to index?  Currently, it's all or nothing
      values_to_index = []
      if values and xapian_options[:values]
        values_to_index = xapian_options[:values]
      end

      # clear any existing data that we might want to replace
      if drop_all_terms && texts
        # as an optimisation, if we're reindexing all of both, we remove everything
        doc.clear_terms
        doc.add_term("M" + self.class.to_s)
        doc.add_term("I" + doc.data)
      else
        term_prefixes_to_index = terms_to_index.map { |x| x[1] }
        for existing_term in doc.terms
          first_letter = existing_term.term[0...1]
          unless "MI".include?(first_letter) # it's not one of the reserved value
            if first_letter.match("^[A-Z]+") # it's a "value" (rather than indexed text)
              if term_prefixes_to_index.include?(first_letter) # it's a value that we've been asked to index
                doc.remove_term(existing_term.term)
              end
            elsif texts
              doc.remove_term(existing_term.term) # it's text and we've been asked to reindex it
            end
          end
        end
      end

      for term in terms_to_index
        value = xapian_value(term[0])
        if value.kind_of?(Array)
          for v in value
            doc.add_term(term[1] + v)
            doc.add_posting(term[1] + v, 1, Integer(term[3])) if term[3]
          end
        else
          doc.add_term(term[1] + value)
          doc.add_posting(term[1] + value, 1, Integer(term[3])) if term[3]
        end
      end

      if values
        doc.clear_values
        for value in values_to_index
          doc.add_value(value[1], xapian_value(value[0], value[3]))
        end
      end

      if texts
        ActsAsXapian.term_generator.document = doc
        for text in texts_to_index
          ActsAsXapian.term_generator.increase_termpos # stop phrases spanning different text fields
          # The "100" here is a weight that could be varied for a boost
          # function. A lower number represents a higher weight, so we set the
          # default to a relatively low weight to give us flexibility either
          # side.
          xapian_value = xapian_value(text, nil, true)
          ActsAsXapian.term_generator.index_text(xapian_value, 100)
        end
      end

      ActsAsXapian.writable_db.replace_document("I" + doc.data, doc)
    end

    # Delete record from the Xapian database
    def xapian_destroy
      ActsAsXapian.writable_db.delete_document("I" + xapian_document_term)
    end

    # Used to mark changes needed by batch indexer
    def xapian_mark_needs_index
      xapian_create_job('update', self.class.base_class.to_s, id)
    end

    def xapian_mark_needs_destroy
      xapian_create_job('destroy', self.class.base_class.to_s, id)
    end

    # Allow reindexing to be skipped if a flag is set
    def xapian_mark_needs_index_if_reindex
      if (respond_to?(:no_xapian_reindex) && no_xapian_reindex == true)
        return true
      end
      xapian_mark_needs_index
    end

    def xapian_create_job(action, model, model_id)
      begin
        ActiveRecord::Base.transaction(requires_new: true) do
          ActsAsXapianJob.
            where([ "model = ? and model_id = ?", model, model_id]).
              delete_all
          xapian_before_create_job_hook(action, model, model_id)
          ActsAsXapianJob.create!(model: model,
                                  model_id: model_id,
                                  action: action)
        end
      rescue ActiveRecord::RecordNotUnique => e
        # Given the error handling in ActsAsXapian::update_index, we can just fail silently if
        # another process has inserted an acts_as_xapian_jobs record for this model.
        unless (e.message =~ /duplicate key value violates unique constraint "index_acts_as_xapian_jobs_on_model_and_model_id"/)
          raise
        end
      end
    end

    # A hook method that can be used in tests to simulate e.g. an external process inserting a record
    def xapian_before_create_job_hook(action, model, model_id)
    end

  end

  ######################################################################
  # Main entry point, add acts_as_xapian to your model.

  module ActsMethods
    # See top of this file for docs
    def acts_as_xapian(options)
      # Give error only on queries if bindings not available
      return unless ActsAsXapian.bindings_available

      include InstanceMethods

      cattr_accessor :xapian_options
      self.xapian_options = options

      ActsAsXapian.init(self.class.to_s, options)

      after_save :xapian_mark_needs_index_if_reindex
      after_destroy :xapian_mark_needs_destroy
    end
  end

end

# Reopen ActiveRecord and include the acts_as_xapian method
ActiveRecord::Base.extend ActsAsXapian::ActsMethods
