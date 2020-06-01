module Project::Queue
  # Public: Extractable requests in the given Project for the given User.
  class Extractable < Base
    def info_requests
      project.info_requests.extractable
    end
  end
end
