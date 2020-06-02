module Project::Queue
  # Public: Extractable requests in the given Project for the given User.
  class Extractable < Base
    def initialize(info_requests, backend)
      super(info_requests.extractable, backend)
    end
  end
end
