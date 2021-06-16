class Survey
  ##
  # A scope to return InfoRequest which can be surveyed
  #
  class InfoRequestQuery
    def initialize(relation = InfoRequest)
      @relation = relation
    end

    def call
      # This can be simplify when https://github.com/rails/rails/pull/41622 is
      # merged and released
      @relation.from(
        InfoRequest.internal.
          where(prominence: 'normal', created_at: Survey.date_range).
          order(:user_id, :created_at).
          arel.distinct_on(@relation.arel_table[:user_id]).as('info_requests')
      )
    end
  end
end
