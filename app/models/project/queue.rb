class Project::Queue
  def initialize(project, current_user, session)
    @project = project
    @current_user = current_user
    @session = session
  end

  def next
    find_current || sample
  end

  def current(info_request_id)
    queue['current'] = info_request_id
  end

  def clear_current
    queue['current'] = nil
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

  def find_current
    info_requests.find_by(id: queue['current']) if queue['current']
  end

  def sample
    info_requests.sample
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
