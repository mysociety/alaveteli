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
        left_joins(:extraction_project_submissions).
        where(project_submissions: { id: nil }).
        classified
    end

    def extracted
      joins(:extraction_project_submissions).distinct
    end
  end
end
