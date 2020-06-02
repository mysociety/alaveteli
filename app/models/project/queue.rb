require_dependency 'project/queue/session_backend'

# Gives the logged in User a new InfoRequest to contribute to.
class Project::Queue
  extend Forwardable

  def self.classifiable(project, session)
    backend = SessionBackend.primed(session, project, :classifiable)
    new(project.info_requests.classifiable, backend)
  end

  def self.extractable(project, session)
    backend = SessionBackend.primed(session, project, :extractable)
    new(project.info_requests.extractable, backend)
  end

  def_delegator :backend, :skip

  def initialize(info_requests, backend)
    @info_requests = info_requests
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
    info_requests == other.info_requests && backend == other.backend
  end

  protected

  attr_reader :info_requests, :backend

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
end
