class Project
  ##
  # An ActiveRecord association extensions with extra InfoRequest scopes for
  # projects
  #
  module InfoRequestExtension
    def classifiable
      where(awaiting_description: true)
    end

    def classified
      where(awaiting_description: false)
    end
  end
end
