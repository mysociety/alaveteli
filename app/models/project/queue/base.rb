module Project::Queue
  # Abstract class for Project task queues.
  # Gives the logged in User a new InfoRequest to contribute to.
  #
  # Subclasses must implement #info_requests.
  class Base
    extend Forwardable
    def_delegator :backend, :skip

    def initialize(project, backend)
      @project = project
      @backend = backend
    end

    def next
      find_and_remember_next
    end

    def clear_skipped
      backend.clear_skipped
    end

    def include?(info_request)
      info_requests.include?(info_request)
    end

    def ==(other)
      project == other.project && backend == other.backend
    end

    protected

    attr_reader :project, :backend

    private

    def find_and_remember_next
      find_next { |info_request| remember_current(info_request) }
    end

    def find_next
      request = find_current || sample
      yield(request) if block_given?
      request
    end

    def find_current
      id = backend.current
      unskipped_requests.find_by(id: id) if id
    end

    def sample
      unskipped_requests.sample
    end

    def remember_current(info_request)
      return backend.clear_current unless info_request
      backend.current = info_request
    end

    def unskipped_requests
      info_requests.where.not(id: backend.skipped)
    end

    def info_requests
      raise NotImplementedError
    end
  end
end
