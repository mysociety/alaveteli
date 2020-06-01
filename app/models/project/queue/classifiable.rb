module Project::Queue
  # Public: Classifiable requests in the given Project for the given User.
  class Classifiable < Base
    def info_requests
      project.info_requests.classifiable
    end
  end
end
