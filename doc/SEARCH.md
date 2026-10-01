# Search Module

The `Search` module decouples the application from any specific search engine.
Controllers, models, mailers, and rake tasks interact with search through a
facade (`Search.search`, `Search.typeahead`, etc.) that delegates to a
pluggable backend. The default backend is Xapian.

## Architecture

```
Controllers / Models / Mailers
        |
        v
  Search module     (app/models/search.rb)           -- public facade
        |
        v
  Search::Backend   (app/models/search/backend.rb)   -- abstract interface
        |
        v
  Adapters::Xapian  (app/models/search/adapters/)    -- concrete implementation
        |
        v
  Search::Adapter   (app/models/search/adapter.rb)   -- base for search types
        |
    +---+---+------------------+
    |       |                  |
FullText  Typeahead   SimilarRequests
    |       |                  |
    v       v                  v
  Search::Results   (app/models/search/results.rb)   -- unified result object
```

### Key classes

| Class | File | Role |
|-------|------|------|
| `Search` | `app/models/search.rb` | Public API facade |
| `Search::Backend` | `app/models/search/backend.rb` | Abstract backend interface |
| `Search::Adapter` | `app/models/search/adapter.rb` | Base class for search operation types |
| `Search::Results` | `app/models/search/results.rb` | Paginated result collection |
| `Search::Context::InfoRequest` | `app/models/search/context/info_request.rb` | Context object for request-scoped searches |

## Using the Search API

### Full-text search

```ruby
# Returns a searchable object; call .results to execute
results = Search.search('freedom of information',
                        models: [InfoRequestEvent],
                        sort_by: 'created_at',
                        sort_ascending: false,
                        collapse_by: 'request_collapse').
            results(page: 1, per_page: 25)

results.results        # [{model:, percent:, ...}, ...]
results.total_estimate # estimated total matches
results.spelling_correction
```

The `sort_by` and `collapse_by` parameters use logical field names.
Each backend maps these to its own internals (e.g. the Xapian adapter
maps `sort_by` to `sort_by_prefix`).

Available sort fields: `created_at`, `described_at`.

Available collapse fields: `request_collapse`, `request_title_collapse`.

### Request search

`Search.request_search` is the keyword search behind site search, the
public body and user pages, and the request list's keyword filter. It
returns one `InfoRequest` per match, so callers and views work in
requests rather than in whatever the backend happened to index:

```ruby
results = Search.request_search('freedom of information',
                                sort_by: 'created_at',
                                sort_ascending: false).
            results(page: 1, per_page: 25)

results.results # [{model: #<InfoRequest>, ...}, ...]
```

Each backend decides which models carry the content it searches. Xapian
searches `InfoRequestEvent`, collapses by `request_collapse`, and maps
each matching event back to its request. PostgreSQL will search the
request and its messages and attachments, and group the hits by request.
So a caller cannot assume what was matched, only that a request matched.

Use it for any keyword search over requests. Use `Search.search` when
you want the matching records themselves, such as annotations.

### Scoped search

`Search.search_scope` (or `Model.search_scope` via the `Searchable`
concern) constrains a search to an ActiveRecord relation and returns a
chainable `ActiveRecord::Relation`, so it composes with conditions,
ordering and pagination on either side of the search:

```ruby
User.active.
  search_scope('alice', admin_mode: true).
  order(:created_at).
  paginate(page: 1, per_page: 100)
```

PostgreSQL backend options (other backends accept and ignore options
they do not support):

| Option | Default | Description |
|--------|---------|-------------|
| `admin_mode` | `false` | Also search the admin-only index. |
| `exact_mode` | `false` | Also match the query as a raw substring. |
| `case_sensitive` | `true` | Only affects `exact_mode`; when `false` substrings match regardless of case. |
| `language` | `nil` | Language for tokenising the query. |
| `limit` | `1000` | Cap on matched records. |

### Forcing a backend

Every facade query method (`search`, `request_search`, `search_scope`,
`typeahead`, `similar`) takes an optional `backend` naming a registered
backend for that one call, overriding the configured `SEARCH_BACKEND`.
This suits callers tied to one backend's features — admin user search
relies on the PostgreSQL-only admin index, so it forces that backend:

```ruby
User.search_scope(query, backend: :postgresql, admin_mode: true)
```

Unknown names raise `ArgumentError`.

### Typeahead / autocomplete

```ruby
results = Search.typeahead('geral',
                           model: PublicBody,
                           exclude_tags: %w[defunct not_apply]).
            results(page: 1, per_page: 10)
```

### Similar requests

```ruby
# Via InfoRequest model (preferred)
searcher = info_request.similar_requests
results  = searcher.results(page: 1, per_page: 10)

# Or use .first for backwards-compatible [items, has_more?] tuple
similar, more = info_request.similar_requests.first(10)
```

Under the hood `InfoRequest#similar_requests` calls
`Search.context(info_request: self).similar_requests`, which goes through
the backend-agnostic facade `Search.similar(info_request)`. The Xapian
backend returns a `Search::Adapters::Xapian::SimilarRequests` searcher.

### Index notification

When a record changes and needs re-indexing:

```ruby
Search.reindex_later(record)
```

This goes to every registered backend, not just the configured one, so
each index stays fresh. Xapian queues a job. PostgreSQL reindexes the
record straight away.

### Request-scoped convenience methods

Request-specific listings live on `InfoRequest`, which delegates to the
search context (`Search.context(info_request: self)`) so the `Search`
facade itself stays model-agnostic.

```ruby
# Front page recent requests
requests = InfoRequest.recent_requests

# Paginated request list (used by RequestController#list)
results = InfoRequest.request_list(filters, page, per_page, max_results)
# => { results: [...], matches_estimated: N, show_no_more_than: N }

# Index health monitoring
Search.queued_jobs_count  # => Integer
```

## Search::Results

All search operations return `Search::Results`, which provides:

### Collection methods

`items`, `results` (alias), `each`, `empty?`, `size`, `length`, `last`,
`to_a`. `Search::Results` includes `Enumerable`, so `any?`, `count`,
`first` and friends come for free via `#each`.

### Pagination

`current_page`, `per_page`, `offset`, `total_estimate` (`matches_estimated`
alias), `total_pages`, `has_more?`, `has_previous?`, `next_page`,
`previous_page`, `first_item_number`, `last_item_number`

### Search metadata

`spelling_correction`, `words_to_highlight`, `has_normal_search_terms?`

## Building a new backend

### 1. Subclass Search::Backend

Create `app/models/search/adapters/example.rb`:

```ruby
module Search
  module Adapters
    module Example
      class Adapter < Search::Backend
        def search(query, models:, sort_by: nil, sort_ascending: true,
                   collapse_by: nil)
          # Return an object that responds to .results(page:, per_page:)
          # and returns a Search::Results
        end

        def request_search(query, sort_by: nil, sort_ascending: true)
          # Same contract as search, but the results must be InfoRequests,
          # one per matching request
        end

        def search_scope(query, relation, **)
          # Return relation narrowed to the matching records
        end

        def typeahead(query, model:, exclude_tags: [])
          # Same contract as search
        end

        def similar(record)
          # Return an object responding to .results / .first for records
          # similar to the given one
        end

        # Optional overrides (have sensible defaults):
        # def reindex_later(record) = nil
        # def queued_jobs_count = 0
      end
    end
  end
end
```

### 2. Implement search operation classes

Each method on the adapter should return an object responding to:

- `results(page:, per_page:)` returning `Search::Results`
- `first(limit)` returning `[items, has_more?]` (optional, has a default
  in `Search::Adapter`)

Use `Search::Adapter` as a base class for shared helpers:

```ruby
class FullTextSearch < Search::Adapter
  def results(page: 1, per_page: 25)
    # query your backend...
    create_search_results(
      items: results,
      total_estimate: count,
      current_page: page,
      per_page: per_page,
      offset: calculate_offset(page, per_page),
      spelling_correction: suggestion,
      words_to_highlight: words
    )
  end
end
```

### 3. Required parameters

The `search` method receives these backend-agnostic parameters:

| Parameter | Type | Description |
|-----------|------|-------------|
| `query` | String | Query string (currently Xapian syntax, see note below) |
| `models` | Array | Model classes to search (`InfoRequestEvent`, `PublicBody`, `User`) |
| `sort_by` | String/nil | Logical field name to sort by |
| `sort_ascending` | Boolean | Sort direction (default `true`) |
| `collapse_by` | String/nil | Logical field name to deduplicate by |

`request_search` takes the same parameters bar `models`, which it picks
itself, and `collapse_by`, which it always applies to the request.

**Note on query syntax:** The query string currently uses Xapian's query
syntax (e.g. `variety:response status:successful`). A future change will
replace this with structured query objects so backends don't need to parse
Xapian syntax.

### 4. Wire it up

Add the adapter to `Search.backends` in `app/models/search.rb`:

```ruby
example: 'Search::Adapters::Example::Adapter'
```

`config/initializers/search.rb` reads the `SEARCH_BACKEND` config value and
assigns `Search.backend` via `Search.backend_for`, at boot and after every
code reload. Selecting the backend is then a config change, not a code edit:

```yaml
# config/general.yml
SEARCH_BACKEND: example
```

### 5. Indexing (if applicable)

If your backend needs indexing configuration (like Xapian does), place it
in your adapter's namespace:

```ruby
# app/models/search/adapters/example/indexing.rb
module Search::Adapters::Example::Indexing
  def self.configure!
    # set up tsvector columns, triggers, etc.
  end
end
```

Call it from an initializer. See
`app/models/search/adapters/xapian/indexing.rb` for the Xapian example.

## Testing

### SearchHelpers module

`spec/support/search_helpers.rb` provides helper methods that stub the
Search module so specs can run without a search index. It is included
automatically in all specs.

#### Stubbing search results

```ruby
# Full-text search
stub_search_results(items: [event1, event2], total: 100)
stub_search_results(items: [], spelling_correction: 'bob')

# Request search (the request listings)
stub_request_search_results(items: [request1, request2], total: 100)

# Typeahead
stub_typeahead_results(items: [body1, body2])

# Similar requests
stub_similar_requests(items: [event1], total: 5)

# Empty results
stub_empty_search_results
stub_empty_typeahead_results
```

#### Building result objects directly

```ruby
results = build_search_results(
  items: [event],
  total: 1,
  page: 1,
  per_page: 25,
  spelling_correction: nil,
  words_to_highlight: ['council'],
  has_normal_search_terms: true
)
```

This returns a `Search::Results` object. Items are automatically wrapped
in `{model: item, percent: 100, ...}` hashes if not already in that format.

### Guard mechanism

A `SearchHelpers::Guard` module is prepended onto
`Search::Adapters::Xapian::Adapter`. In non-`:xapian` tagged specs, all
`search`/`request_search`/`typeahead`/`similar` calls return a
`NullSearcher` that produces empty results, preventing any Xapian database
access in unit tests.

To run specs that hit the real Xapian index, tag them with `:xapian`:

```ruby
RSpec.describe 'search queries', :xapian do
  it 'finds events by keyword' do
    results = Search.search('fancy dog', models: [InfoRequestEvent]).
                results(page: 1, per_page: 10)
    expect(results).to be_present
  end
end
```

### Contract specs

#### Shared backend contract

`spec/models/search/shared_examples/backend_contract.rb` defines
`shared_examples 'a search backend'`, the interface every adapter must
satisfy: a composable `search_scope`, a `search` that pages, sorts and
collapses, returning `Search::Results` items keyed by `:model`, a
`request_search` that pages and returns each matching InfoRequest once,
`reindex_later`, and `queued_jobs_count`. Run it against a new adapter by
including it with a `subject` and an indexed backend tag:

```ruby
require_relative '../shared_examples/backend_contract'

RSpec.describe Search::Adapters::Example::Adapter do
  subject(:adapter) { described_class.new }
  it_behaves_like 'a search backend'
end
```

The Xapian adapter already includes it in
`spec/models/search/adapters/xapian_spec.rb`. A backend that only
supports `search_scope`, like PostgreSQL, uses
`'a scoped search backend'` instead.

#### Query contract

`spec/models/search/queries_spec.rb` tests the search query contract against the
real Xapian backend. These specs verify that query syntax, prefix terms,
collapsing, sorting, and spelling correction work correctly with actual
indexed fixture data.

When building a new backend, write equivalent specs to ensure your
implementation satisfies the same contract. The query patterns tested
include:

- Text search (single words, quoted phrases, multi-word)
- Prefix term filtering (`requested_by:`, `status:`, `variety:`, etc.)
- Model class filtering (searching only `InfoRequestEvent`, `PublicBody`, or `User`)
- Status filtering (`latest_status:`, `waiting_classification:`)
- Collapsing (`request_collapse`, `request_title_collapse`)
- Sorting by `created_at` and `described_at`
- Spelling correction
- Highlight words

### Writing specs for code that searches

Prefer stubbing at the Search facade level rather than at the backend:

```ruby
# Good: stubs the public API
stub_search_results(items: [event])

# Avoid: couples test to a specific backend
allow(ActsAsXapian::Search).to receive(:new).and_return(...)
```

When testing that specific search parameters are passed, stub and
set expectations on `Search`:

```ruby
searcher = double('searcher', results: search_results)
expect(Search).to receive(:search).with(
  'test query',
  models: [InfoRequestEvent],
  sort_by: 'described_at',
  sort_ascending: true
).and_return(searcher)
```

## File layout

```
app/models/
  search.rb                           # Public facade and convenience methods
app/models/search/
  backend.rb                          # Abstract backend interface
  adapter.rb                          # Base class for search operation types
  results.rb                          # Paginated result collection
  event_search.rb                     # Shared InfoRequestEvent search helper
  request_list.rb                     # Paginated request list
  recent_requests.rb                  # Front page recent requests
  stats.rb                            # Admin search timings and query plans
  track_events.rb                     # Picks how a track finds new events
  track_events/                       # One class per kind of track
  context/
    info_request.rb                   # Context for request-scoped searches
  adapters/
    postgresql.rb                     # PostgreSQL backend adapter
    xapian.rb                         # Xapian backend adapter
    xapian/
      full_text_search.rb             # Wraps ActsAsXapian::Search
      request_search.rb               # Event search mapped back to requests
      similar_requests.rb             # Wraps ActsAsXapian::Similar
      typeahead.rb                    # Xapian typeahead query prep + execution
      indexing.rb                     # acts_as_xapian model configuration

spec/models/
  search_spec.rb                      # Search facade specs
spec/models/search/
  backend_spec.rb                     # Backend base class specs
  adapter_spec.rb                     # Adapter base class specs
  results_spec.rb                     # Results collection specs
  queries_spec.rb                     # Query contract specs (tagged :xapian)
  request_list_spec.rb                # Request list specs
  recent_requests_spec.rb             # Recent requests specs
  stats_spec.rb                       # Search stats specs
  track_events_spec.rb                # Track strategy selection specs
  track_events/                       # Specs for each kind of track
  shared_examples/
    backend_contract.rb               # shared backend contracts
  context/
    info_request_spec.rb              # Context specs
  adapters/postgresql_spec.rb         # PostgreSQL adapter specs
  adapters/xapian_spec.rb             # Xapian adapter contract specs
  adapters/xapian/
    full_text_search_spec.rb          # Xapian full-text specs (:xapian)
    similar_requests_spec.rb          # Xapian similar specs (:xapian)
    typeahead_spec.rb                 # Xapian typeahead specs (:xapian)
    indexing_spec.rb                  # Indexing configuration specs
spec/support/
  search_helpers.rb                   # Stubbing helpers for all specs
```

# Search in Alaveteli

Alaveteli is moving from `xapian`, which it has used since its creation, to the `postgresql` database's own search.

The goal is to simplify the code (by storing all data in a single place) by allowing to chain rails ORM calls directly after the search call itself. This avoids an expensive pattern where `xapian` (or another external search index) is first called, then checks need to be done in postgresql, eg. to verify permissions. It also simplifies deployment, as there is no need for a separate search tool to deploy and maintain.

## Architecture

All search data is stored in a separate `search_documents` table, which is filled from content stored elsewhere.

The word `indexing` is used in two different ways in this document:

- `object.reindex` will upsert content into the `search_documents` table (backed by the `SearchDocument` rails model. This makes the data visible to the search system.
- When data is written in `search_documents`, postgresql has several indices on the table, which will be refreshed. This happens automatically, no specific code is required for this beyond the call above. These indices are what makes search fast, but have no impact on what can or cannot be found by the search system.

### The search_documents table

#### public vs admin

It contains 2 sets of columns:
- the "public" search columns, which should only contain data that anyone can see,
- the "admin" search columns, which should contain anything that only admins are allowed to see.

For each set, there are 2 columns:

#### raw_content

`raw_content` (respectively `raw_admin_content`) stores plain text for a model instance, typically a concatenation of the various fields we want to be able to search. This field can be expensive to rebuild (eg. it can contain multiple ruby method calls, or even require pulling a file from S3).

It is kept in the database to back the "exact" search (using SQL `LIKE`, or `ILIKE` when `case_sensitive: false` is passed). A use case for this is finding all users whose email address uses `@somedomain.com`. It would be possible to get rid of this column, and implement an "exact" search using a SQL query for each model. This would not work for models that do not store all their content in the database (`FoiAttachment` for instance).

There is no index to back this search type at the moment (it would use the built-in `pg_trgm` index type, which is quite heavy to build and maintain), but it can be added if it becomes apparent that it is needed. This would allow typo-tolerant search, on top of speeding up "exact" searches.

#### content_tsv

`content_tsv` (resp. `admin_content_tsv`) stores the searchable data stemmed and tokenised according to the language used by the platform (or the specific content where multiple languages are used). postgresql uses `ts_vector` format for this.

The `ts_vector` search system only searches words by their start (ie. it can search for `the_user@somedomain.com` if it is the full email address, but it won't match the domain only without some further custom preprocessing). This is the part that will match `requester`, `requesting`, etc... when searching for `request`. But it will not find `request` if the search has a typo, such as swapped letters.

## Semantic search

There is currently no semantic search support. It would be relatively easy to add a vector column to the `search_documents` table, the harder part being to run the LLM to produce the vectors.

## Usage

### Indexing objects

Updating the search index for an object is as simple as `object.reindex`, eg. `PublicBody.find(123).reindex`.

It is possible to reindex the entire set of objects for a model with `PublicBody.reindex_all`. This will not remove existing entries, but overwrite them in batches. This means it is possible to reindex the entire dataset without service interruption.

Beware though, that this operation can take several minutes to several days for larger setups when reindexing all `FoiAttachment`s for instance.

The preferred logic (after initial backfilling of the `search_documents` table) is to `.reindex` a model after it has had modifications that would affect its searchable content.

### Defining what is indexed

Add a `searchable` definition on a model to make it searchable. It looks like this:

```ruby
  searchable index: {
               ".name": "A",
               "home_page": "B",
             },
             admin_index: {
               # same logic as above
             }
```
The above means:
- `.name` (note the leading `.`) calls the ruby method `object.name` (which should return a string).
- `home_page` uses the postgresql column directly (this is much faster, but less flexible)

The letter that follows `A|B|C|D` defines the weights assigned to the field for the `ts_vector` value, with A being highest. This is used to rank results.

### How indexing happens

When you run `object.reindex`, the following happens:
- the `raw_content` is built from the model's `searchable` definition,
- the `content_tsv` is built from the same definition, pulling data directly from the model's fields (it cannot be built from `raw_content` because there is no weight information in it)
- the same process is done for the `admin_index` elements.
- all fields are upserted in `search_documents`. postgresql automatically updates its indices to reflect the data in the table.

There is nothing further to call for this data to be searchable.

### Searching

Searching through the entire database can be done with:

```ruby
SearchDocument.newsearch("some text")
```
This returns a `ActiveRecord::Relation` of `SearchDocument` which can then be chained with rails ORM calls.

Searching for a single model is done with:
```ruby
PublicBody.newsearch("some text")
```
It returns the same `ActiveRecord::Relation` of whatever model was used to call the search (`PublicBody` in this example.

The method takes optional keyword arguments:
- `admin_mode` (default: `false`), set to `true` to search for content that is not public.
- `exact_mode` (default: `false`), set to `true` to use the SQL `LIKE` search.
- `language` (default: `nil`) pass a language to limit search to the given translation. This only makes sense for translated models, it won't return anything for untranslated models. By default, search in any language.
- `limit` (default: 10) is pretty obvious. Setting the limit too low might prevent relevant results from being returned.
