class SearchDocument
  # Filters out any item that is linked to an InfoRequest
  # that is under embargo (InfoRequest, IncomingMessage,
  # OutgoingMessage, FoiAttachment)
  class NotEmbargoedQuery
    def initialize(relation = SearchDocument)
      @relation = relation
    end

    def call
      @relation.
        joins(
          "LEFT OUTER JOIN embargoes embargo " \
          "ON embargo.info_request_id = search_documents.root_id " \
          "AND search_documents.root_type = 'InfoRequest'"
        ).where("embargo.id is null")
    end
  end
end
