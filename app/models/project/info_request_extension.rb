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
      scope = where(described_state: EXTRACTABLE_STATES).
        left_joins(:extraction_project_submissions).
        classified

      scope.where(project_submissions: { id: nil }).or(
        scope.where.not(project_submissions: { project: project })
      )
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
