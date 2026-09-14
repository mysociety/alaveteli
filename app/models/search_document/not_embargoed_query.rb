class SearchDocument
  # Filters out any item that is linked to an InfoRequest
  # that is under embargo (InfoRequest, IncomingMessage,
  # OutgoingMessage, FoiAttachment)
  class NotEmbargoedQuery
    def initialize(relation = SearchDocument)
      @relation = relation
    end

    def call
      # we need to handle each SearchDocument type differently here,
      # so we join multiple times on embargoes
      @relation.joins(
          # InfoRequest
          "LEFT OUTER JOIN embargoes embargo_ir " \
          "ON embargo_ir.info_request_id = search_documents.searchable_id " \
          "AND search_documents.searchable_type = 'InfoRequest'"
        ).joins(
          # OutgoingMessage
          "LEFT OUTER JOIN outgoing_messages om " \
          "ON om.id = search_documents.searchable_id " \
          "AND search_documents.searchable_type = 'OutgoingMessage' " \
          "LEFT OUTER JOIN embargoes embargo_om " \
          "ON embargo_om.info_request_id = om.info_request_id"
        ).joins(
          # IncomingMessage
          "LEFT OUTER JOIN incoming_messages im " \
          "ON im.id = search_documents.searchable_id " \
          "AND search_documents.searchable_type = 'IncomingMessage' " \
          "LEFT OUTER JOIN embargoes embargo_im " \
          "ON embargo_im.info_request_id = im.info_request_id"
        ).joins(
          # FoiAttachment
          "LEFT OUTER JOIN foi_attachments fa " \
          "ON fa.id = search_documents.searchable_id " \
          "AND search_documents.searchable_type = 'FoiAttachment' " \
          "LEFT OUTER JOIN incoming_messages fa_im " \
          "ON fa.incoming_message_id = fa_im.id " \
          "LEFT OUTER JOIN embargoes embargo_fa " \
          "ON embargo_fa.info_request_id = fa_im.info_request_id"
        ).where("embargo_om.id is null")
          .where("embargo_ir.id is null")
          .where("embargo_im.id is null")
          .where("embargo_fa.id is null")
    end
  end
end
