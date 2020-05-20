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
      @relation.joins(
        "LEFT JOIN project_resources r1 ON " \
        "r1.resource_id = info_requests.id AND " \
        "r1.resource_type = 'InfoRequest'"
      ).
      joins(
        "LEFT JOIN project_resources r2 ON " \
        "r2.resource_id = info_requests.info_request_batch_id AND " \
        "r2.resource_type = 'InfoRequestBatch'"
      ).
      where("r1.project_id = :id OR r2.project_id = :id", id: project.id)
    end
  end
end
