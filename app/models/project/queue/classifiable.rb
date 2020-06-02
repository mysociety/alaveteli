module Project::Queue
  # Public: Classifiable requests in the given Project for the given User.
  class Classifiable < Base
    def initialize(info_requests, backend)
      super(info_requests.classifiable, backend)
    end
  end
end
