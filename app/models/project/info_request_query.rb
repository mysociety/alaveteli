class Project
  ##
  # A association query between Project and InfoRequest. This is complex than a
  # standard association as InfoRequest can belong to Project directly or via an
  # InfoRequestBatch
  #
  class InfoRequestQuery
    def initialize(relation = InfoRequest)
      @relation = relation
    end

    def call(project)
      table = Project::Resource.table_name

      @relation.joins(<<~JOIN).where(table => { project_id: project })
        INNER JOIN #{table} ON (
          #{table}.resource_id = info_requests.id AND
          #{table}.resource_type = 'InfoRequest'
        ) OR (
          #{table}.resource_id = info_requests.info_request_batch_id AND
          #{table}.resource_type = 'InfoRequestBatch'
        )
      JOIN
    end
  end
end
