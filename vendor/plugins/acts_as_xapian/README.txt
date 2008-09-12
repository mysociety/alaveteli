Do patch this file if there is documentation missing / wrong. It's called
README.txt and is in git, using Textile formatting. The wiki page is just
copied from the README.txt file.

Contents
========

* a. Introduction to acts_as_xapian 
* b. Installation
* c. Comparison to acts_as_solr (as on 24 April 2008)
* d. Documentation - indexing
* e. Documentation - querying
* f. Configuration
* g. Support


a. Introduction to acts_as_xapian
=================================

"Xapian":http://www.xapian.org is a full text search engine library which has
Ruby bindings. acts_as_xapian adds support for it to Rails. It is an
alternative to acts_as_solr, acts_as_ferret, Ultrasphinx, acts_as_indexed,
acts_as_searchable or acts_as_tsearch.

acts_as_xapian is deployed in production on these websites.
* "WhatDoTheyKnow":http://www.whatdotheyknow.com 
* "MindBites":http://www.mindbites.com

The section "c. Comparison to acts_as_solr" below will give you an idea of 
acts_as_xapian's features.

acts_as_xapian was started by Francis Irving in May 2008 for search and email
alerts in WhatDoTheyKnow, and so was supported by "mySociety":http://www.mysociety.org 
and initially paid for by the "JRSST Charitable Trust":http://www.jrrt.org.uk/jrsstct.htm


b. Installation
===============

Retrieve the plugin directly from the git version control system by running
this command within your Rails app.

    git clone git://github.com/frabcus/acts_as_xapian.git vendor/plugins/acts_as_xapian

Xapian 1.0.5 and associated Ruby bindings are also required. 

Debian or Ubuntu - install the packages libxapian15 and libxapian-ruby1.8. 

Mac OSX - follow the instructions for installing from source on 
the "Installing Xapian":http://xapian.org/docs/install.html page - you need the
Xapian library and bindings (you don't need Omega).

There is no Ruby Gem for Xapian, it would be great if you could make one!


c. Comparison to acts_as_solr (as on 24 April 2008)
=============================

* Offline indexing only mode - which is a minus if you want changes
immediately reflected in the search index, and a plus if you were going to
have to implement your own offline indexing anyway.

* Collapsing - the equivalent of SQL's "group by". You can specify a field
to collapse on, and only the most relevant result from each value of that
field is returned. Along with a count of how many there are in total.
acts_as_solr doesn't have this.

* No highlighting - Xapian can't return you text highlighted with a search
query. You can try and make do with TextHelper::highlight (combined with
words_to_highlight below). I found the highlighting in acts_as_solr didn't
really understand the query anyway.

* Date range searching - this exists in acts_as_solr, but I found it
wasn't documented well enough, and was hard to get working.

* Spelling correction - "did you mean?" built in and just works.

* Similar documents - acts_as_xapian has a simple command to find other models
that are like a specified model.

* Multiple models - acts_as_xapian searches multiple types of model if you
like, returning them mixed up together by relevancy. This is like
multi_solr_search, only it is the default mode of operation and is properly
supported.

* No daemons - However, if you have more than one web server, you'll need to
work out how to use "Xapian's remote backend":http://xapian.org/docs/remote.html.

* One layer - full-powered Xapian is called directly from the Ruby, without
Solr getting in the way whenever you want to use a new feature from Lucene.

* No Java - an advantage if you're more used to working in the rest of the
open source world. acts_as_xapian, it's pure Ruby and C++.

* Xapian's awesome email list - the kids over at 
"xapian-discuss":http://lists.xapian.org/mailman/listinfo/xapian-discuss
are super helpful. Useful if you need to extend and improve acts_as_xapian. The
Ruby bindings are mature and well maintained as part of Xapian.


d. Documentation - indexing
===========================

Xapian is an *offline indexing* search library - only one process can have the
Xapian database open for writing at once, and others that try meanwhile are
unceremoniously kicked out. For this reason, acts_as_xapian does not support
immediate writing to the database when your models change.

Instead, there is a ActsAsXapianJob model which stores which models need
updating or deleting in the search index. A rake task 'xapian:update_index'
then performs the updates since last change. You can run it on a cron job, or
similar.

Here's how to add indexing to your Rails app:

1. Put acts_as_xapian in your models that need search indexing. e.g.

    acts_as_xapian :texts => [ :name, :short_name ],
       :values => [ [ :created_at, 0, "created_at", :date ] ],
       :terms => [ [ :variety, 'V', "variety" ] ]

Options must include:

* :texts, an array of fields for indexing with full text search. 
e.g. :texts => [ :title, :body ]

* :values, things which have a range of values for sorting, or for collapsing. 
Specify an array quadruple of [ field, identifier, prefix, type ] where 
** identifier is an arbitary numeric identifier for use in the Xapian database
** prefix is the part to use in search queries that goes before the :
** type can be any of :string, :number or :date

e.g. :values => [ [ :created_at, 0, "created_at", :date ],
[ :size, 1, "size", :string ] ]

* :terms, things which come with a prefix (before a :) in search queries. 
Specify an array triple of [ field, char, prefix ] where 
** char is an arbitary single upper case char used in the Xapian database, just
pick any single uppercase character, but use a different one for each prefix.
** prefix is the part to use in search queries that goes before the :
For example, if you were making Google and indexing to be able to later do a
query like "site:www.whatdotheyknow.com", then the prefix would be "site".

e.g. :terms => [ [ :variety, 'V', "variety" ] ]
        
A 'field' is a symbol referring to either an attribute or a function which
returns the text, date or number to index. Both 'identifier' and 'char' must be
the same for the same prefix in different models.

Options may include:
* :eager_load, added as an :include clause when looking up search results in
database
* :if, either an attribute or a function which if returns false means the
object isn't indexed

2. Generate a database migration to create the ActsAsXapianJob model:

    script/generate acts_as_xapian
    rake db:migrate

3. Call 'rake xapian:rebuild_index models="ModelName1 ModelName2"' to build the index
the first time (you must specify all your indexed models). It's put in a
development/test/production dir in acts_as_xapian/xapiandbs. See f. Configuration 
below if you want to change this.

4. Then from a cron job or a daemon, or by hand regularly!, call 'rake xapian:update_index'


e. Documentation - querying
===========================

Testing indexing
----------------

If you just want to test indexing is working, you'll find this rake task
useful (it has more options, see tasks/xapian.rake)

    rake xapian:query models="PublicBody User" query="moo"

Performing a query
------------------

To perform a query from code call ActsAsXapian::Search.new. This takes in turn:
* model_classes - list of models to search, e.g. [PublicBody, InfoRequestEvent]
* query_string - Google like syntax, see below

And then a hash of options:
* :offset - Offset of first result (default 0)
* :limit - Number of results per page
* :sort_by_prefix - Optionally, prefix of value to sort by, otherwise sort by relevance
* :sort_by_ascending - Default true (documents with higher values better/earlier), set to false for descending sort
* :collapse_by_prefix - Optionally, prefix of value to collapse by (i.e. only return most relevant result from group)

Google like query syntax is as described in 
    "Xapian::QueryParser Syntax":http://www.xapian.org/docs/queryparser.html
Queries can include prefix:value parts, according to what you indexed in the
acts_as_xapian part above. You can also say things like model:InfoRequestEvent 
to constrain by model in more complex ways than the :model parameter, or
modelid:InfoRequestEvent-100 to only find one specific object.

Returns an ActsAsXapian::Search object. Useful methods are:
* description - a techy one, to check how the query has been parsed
* matches_estimated - a guesstimate at the total number of hits
* spelling_correction - the corrected query string if there is a correction, otherwise nil
* words_to_highlight - list of words for you to highlight, perhaps with TextHelper::highlight
* results - an array of hashes each containing:
** :model - your Rails model, this is what you most want!
** :weight - relevancy measure
** :percent - the weight as a %, 0 meaning the item did not match the query at all
** :collapse_count - number of results with the same prefix, if you specified collapse_by_prefix

Finding similar models
----------------------

To find models that are similar to a given set of models call ActsAsXapian::Similar.new. This takes:
* model_classes - list of model classes to return models from within
* models - list of models that you want to find related ones to

Returns an ActsAsXapian::Similar object. Has all methods from ActsAsXapian::Search above, except
for words_to_highlight. In addition has:
* important_terms - the terms extracted from the input models, that were used to search for output
You need the results methods to get the similar models.


f. Configuration
================

If you want to customise the configuration of acts_as_xapian, it will look for a file called 'xapian.yml'
under RAILS_ROOT/config. As is familiar from the format of the database.yml file, separate :development,
:test and :production sections are expected.

The following options are available:
* base_db_path - specifies the directory, relative to RAILS_ROOT, in which acts_as_xapian stores its 
search index databases. Default is the directory xapiandbs within the acts_as_xapian directory.

g. Support
==========

Please ask any questions on the 
"acts_as_xapian Google Group":http://groups.google.com/group/acts_as_xapian

The official home page and repository for acts_as_xapian are the
"acts_as_xapian github page":http://github.com/frabcus/acts_as_xapian/wikis

For more details about anything, see source code in lib/acts_as_xapian.rb

Merging source instructions "Using git for collaboration" here:
http://www.kernel.org/pub/software/scm/git/docs/gittutorial.html
