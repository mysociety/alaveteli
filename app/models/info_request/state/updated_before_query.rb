class InfoRequest
  module State
    class UpdatedBeforeQuery
      DEFAULT_TIMESTAMP = Time.zone.now

      def initialize(params = {}, relation = InfoRequest)
        @relation = relation
        @params = params
      end

      def timestamp
        if @params[:timestamp]
          @params[:timestamp]
        else
          DEFAULT_TIMESTAMP
        end
      end

      def call
        sql = <<-EOF
info_requests.id IN (
  SELECT id FROM (
    SELECT info_requests.id, max(outgoing_messages.created_at) FROM info_requests
    LEFT OUTER JOIN outgoing_messages
      ON outgoing_messages.info_request_id = info_requests.id
    GROUP BY info_requests.id
    HAVING greatest(max(outgoing_messages.created_at), info_requests.updated_at) < ?
  ) req_id
)
EOF
        @relation.where(sql, timestamp)
      end
    end
  end
end
