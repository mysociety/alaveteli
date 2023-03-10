class Project
  ##
  # An ActiveRecord association extensions with extra InfoRequest scopes for
  # projects
  #
  module InfoRequestExtension
    EXTRACTABLE_STATES = %w(successful partially_successful)

    def classifiable
      where(awaiting_description: true)
    end

    def classified
      where(awaiting_description: false)
    end

    def extractable
      where(described_state: EXTRACTABLE_STATES).
        joins(
          <<~SQL.squish
            LEFT OUTER JOIN "project_submissions" ON
            "project_submissions"."resource_type" = 'Dataset::ValueSet' AND
            "project_submissions"."info_request_id" = "info_requests"."id" AND
            "project_submissions"."project_id" = #{project.id}
          SQL
        ).
        where(project_submissions: { id: nil }).
        classified
    end

    def extracted
      joins(:extraction_project_submissions).
        where(project_submissions: { project: project }).
        distinct
    end

    private

    def project
      proxy_association.owner
    end
  end
end
