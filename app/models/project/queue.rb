# Abstract class for Project task queues.
# Gives the logged in User a new InfoRequest to contribute to.
#
# Subclasses must implement #info_requests.
class Project::Queue
  def initialize(project, current_user, session)
    @project = project
    @current_user = current_user
    @session = session
  end

  def next
    find_and_remember_next
  end

  def include?(info_request)
    info_requests.include?(info_request)
  end

  def ==(other)
    project == other.project &&
      current_user == other.current_user &&
      session == other.session
  end

  protected

  attr_reader :project, :current_user, :session

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
    info_requests.find_by(id: current) if current
  end

  def sample
    info_requests.sample
  end

  def remember_current(info_request)
    return queue['current'] = nil unless info_request
    queue['current'] = info_request.id.to_s
  end

  def current
    queue['current']
  end

  def queue
    prime_session
    session['projects'][project.id.to_s][queue_name]
  end

  def prime_session
    @prime_session ||= prime_session!
  end

  def prime_session!
    session['projects'] ||= {}
    session['projects'][project.id.to_s] ||= {}
    session['projects'][project.id.to_s][queue_name] ||= {}
    session['projects'][project.id.to_s][queue_name]['current'] ||= nil
    true
  end

  # e.g: Project::Queue::Classifiable => "classifiable"
  def queue_name
    self.class.to_s.demodulize.underscore
  end

  def info_requests
    raise NotImplementedError
  end
end
