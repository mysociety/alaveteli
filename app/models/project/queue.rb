class Project::Queue
  def initialize(project, current_user, session)
    @project = project
    @current_user = current_user
    @session = session
  end

  def next
    request = find_next
    return unless request
    current(request.id)
    request
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

  def find_next
    find_current || sample
  end

  def find_current
    Rails.logger.debug "#{self.class}|#{queue_key}#find_current"
    Rails.logger.debug "#{self.class}|#{queue_key}#current? #{queue['current']}"
    info_requests.find_by(id: queue['current']) if queue['current']
  end

  def sample
    Rails.logger.debug "#{self.class}|#{queue_key}#sample"
    info_requests.sample
  end

  def current(info_request_id)
    Rails.logger.debug "#{self.class}|#{queue_key}#current:#{info_request_id}"
    queue['current'] = info_request_id.to_s
  end

  def queue_key
    "projects/#{project.id}/#{queue_name}"
  end

  def queue
    prime_session
    session['projects'][project.id.to_s][queue_name]
  end

  def prime_session
    @prime_session ||= prime_session!
  end

  def prime_session!
    Rails.logger.debug "#{self.class}|#{queue_key}#prime_session!1 #{session['projects']}"
    session['projects'] ||= {}
    session['projects'][project.id.to_s] ||= {}
    session['projects'][project.id.to_s][queue_name] ||= {}
    session['projects'][project.id.to_s][queue_name]['current'] ||= nil
    Rails.logger.debug "#{self.class}|#{queue_key}#prime_session!2 #{session['projects']}"
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
