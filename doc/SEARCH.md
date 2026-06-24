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
  Search module          (app/search/search.rb)    -- public facade
        |
        v
  Search::Backend        (app/search/backend.rb)   -- abstract interface
        |
        v
  Adapters::Xapian       (app/search/adapters/)    -- concrete implementation
        |
        v
  Search::Adapter        (app/search/adapter.rb)   -- base for search types
        |
    +---+---+------------------+
    |       |                  |
FullText  Typeahead   SimilarRequests
    |       |                  |
    v       v                  v
  Search::Results        (app/search/results.rb)   -- unified result object
```

### Key classes

| Class | File | Role |
|-------|------|------|
| `Search` | `app/search/search.rb` | Public API facade |
| `Search::Backend` | `app/search/backend.rb` | Abstract backend interface |
| `Search::Adapter` | `app/search/adapter.rb` | Base class for search operation types |
| `Search::Results` | `app/search/results.rb` | Paginated result collection |
| `Search::Context::InfoRequest` | `app/search/context/info_request.rb` | Context object for request-scoped searches |

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

Backends with async indexing (Xapian) queue a job. Backends where the
search index is the database itself (e.g. PostgreSQL) can leave this
as a no-op.

### Query role vs index role

The facade splits the two backend roles. `Search.backend` is the single
backend that answers queries (`search`, `typeahead`, `similar`,
`search_scope`). `Search.index_backends` is the list of backends kept fresh
on writes; `Search.reindex_later` and `Search.queued_jobs_count` fan out
across it.

```ruby
Search.backend         # => the live query backend
Search.index_backends  # => [Search.backend] by default
```

During a transition both indexes must stay current while only one answers
queries, so you can index into several backends but query just one:

```ruby
Search.backend = xapian            # queries go to Xapian
Search.index_backends = [xapian, postgresql] # both stay indexed
```

### Request-scoped convenience methods

Request-specific listings live on `InfoRequest`, which delegates to the
search context (`Search.context(info_request: self)`) so the `Search`
facade itself stays model-agnostic.

```ruby
# Front page recent requests
events, all_successful = InfoRequest.recent_requests

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

Create `app/search/adapters/postgresql.rb` (or similar):

```ruby
module Search
  module Adapters
    module PostgreSQL
      class Adapter < Search::Backend
        def search(query, models:, sort_by: nil, sort_ascending: true,
                   collapse_by: nil)
          # Return an object that responds to .results(page:, per_page:)
          # and returns a Search::Results
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

**Note on query syntax:** The query string currently uses Xapian's query
syntax (e.g. `variety:response status:successful`). A future change will
replace this with structured query objects so backends don't need to parse
Xapian syntax.

### 4. Wire it up

Set the backend in an initializer or via configuration:

```ruby
Search.backend = Search::Adapters::PostgreSQL::Adapter.new
```

`config/initializers/search.rb` reads the `SEARCH_BACKEND` config value and
assigns `Search.backend` via `Search.backend_for`. Selecting the backend is
then a config change, not a code edit:

```yaml
# config/general.yml
SEARCH_BACKEND: postgresql
```

To populate a second index during a transition without making it answer
queries yet, add it to `Search.index_backends` (see "Query role vs index
role" above).

### 5. Indexing (if applicable)

If your backend needs indexing configuration (like Xapian does), place it
in your adapter's namespace:

```ruby
# app/search/adapters/postgresql/indexing.rb
module Search::Adapters::PostgreSQL::Indexing
  def self.configure!
    # set up tsvector columns, triggers, etc.
  end
end
```

Call it from an initializer. See
`app/search/adapters/xapian/indexing.rb` for the Xapian example.

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
`search`/`typeahead`/`similar` calls return a `NullSearcher` that produces
empty results, preventing any Xapian database access in unit tests.

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

`spec/search/shared_examples/backend_contract.rb` defines
`shared_examples 'a search backend'`, the interface every adapter must
satisfy (composable `search_scope`, `search(...).results(page:, per_page:)`
returning `Search::Results`, `reindex_later`, and `queued_jobs_count`). Run
it against a new adapter by including it with a `subject` and an indexed
backend tag:

```ruby
require_relative '../shared_examples/backend_contract'

RSpec.describe Search::Adapters::PostgreSQL::Adapter, :postgresql do
  subject(:adapter) { described_class.new }
  it_behaves_like 'a search backend'
end
```

The Xapian adapter already includes it in
`spec/search/adapters/xapian_spec.rb`.

#### Query contract

`spec/search/queries_spec.rb` tests the search query contract against the
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
app/search/
  backend.rb                          # Abstract backend interface
  adapter.rb                          # Base class for search operation types
  results.rb                          # Paginated result collection
  search.rb                           # Public facade and convenience methods
  context/
    info_request.rb                   # Context for request-scoped searches
  adapters/
    xapian.rb                         # Xapian backend adapter
    xapian/
      full_text_search.rb             # Wraps ActsAsXapian::Search
      similar_requests.rb             # Wraps ActsAsXapian::Similar
      typeahead.rb                    # Xapian typeahead query prep + execution
      indexing.rb                     # acts_as_xapian model configuration

spec/search/
  backend_spec.rb                     # Backend base class specs
  adapter_spec.rb                     # Adapter base class specs
  results_spec.rb                     # Results collection specs
  search_spec.rb                      # Search facade specs
  queries_spec.rb                     # Query contract specs (tagged :xapian)
  backend_selection_spec.rb           # Config-driven backend selection specs
  shared_examples/
    backend_contract.rb               # 'a search backend' shared contract
  context/
    info_request_spec.rb              # Context specs
  adapters/xapian/
    full_text_search_spec.rb          # Xapian full-text specs (:xapian)
    similar_requests_spec.rb          # Xapian similar specs (:xapian)
    typeahead_spec.rb                 # Xapian typeahead specs (:xapian)
    indexing_spec.rb                  # Indexing configuration specs
spec/support/
  search_helpers.rb                   # Stubbing helpers for all specs
```
