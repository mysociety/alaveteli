module Search
  ##
  # Times a search query and keeps hold of the SQL behind it, so admin
  # listings can show what a search cost. Counting the matches and loading
  # the page are timed apart, as counting is often the slower of the two.
  #
  # Takes the paginated relation a listing renders, so +count+ is every
  # match rather than the page.
  #
  #   relation = PublicBody.search_scope('foi').paginate(page: 1)
  #   stats = Search::Stats.measure(relation)
  #   stats.count     # => 42
  #   stats.duration  # => 0.031
  #
  class Stats
    attr_reader :relation, :count, :count_duration, :load_duration

    def self.measure(relation)
      new(relation).measure
    end

    def initialize(relation)
      @relation = relation
    end

    def measure
      @count_duration = timed { @count = relation.total_entries }
      @load_duration = timed { relation.load }
      self
    end

    def duration
      count_duration + load_duration
    end

    def sql
      @sql ||= relation.to_sql
    end

    # Ask PostgreSQL what it actually did with the query. This runs the
    # query again, so only do it when someone asks to see it. The query
    # cache has to be off or EXPLAIN sees a cached result and reports
    # nothing.
    def explain
      @explain ||= relation.klass.uncached do
        relation.explain(:analyze, :buffers).inspect
      end
    end

    private

    def timed
      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      yield
      Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
    end
  end
end
