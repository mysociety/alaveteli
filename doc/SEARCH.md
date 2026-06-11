# Search in Alaveteli

Alaveteli uses the postgresql database's search capabilities in replacement of `xapian` that was used since its creation.

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

It is kept in the database to back the "exact" search (using SQL `LIKE`). A use case for this is finding all users whose email address uses `@somedomain.com`. It would be possible to get rid of this column, and implement an "exact" search using a SQL query for each model. This would not work for models that do not store all their content in the database (`FoiAttachment` for instance).

There is no index to back this search type at the moment (it would use the built-in `pg_trgm` index type, which is quite heavy to build and maintain), but it can be added if it becomes apparent that it is needed. This would allow typo-tolerant search, on top of speeding up "exact" searches.

#### content_tsv

`content_tsv` (resp. `admin_content_tsv`) stores the searchable data stemmed and tokenised according to the language used by the platform (or the specific content where multiple languages are used). postgresql uses `ts_vector` format for this.

The `ts_vector` search system only searches words by their start (ie. it can search for `the_user@somedomain.com` if it is the full email address, but it won't match the domain only without some further custom preprocessing). This is the part that will match `requester`, `requesting`, etc... when searching for `request`. But it will not find `reuqest` (typo).

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
