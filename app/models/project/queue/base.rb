module Project::Queue
  # Abstract class for Project task queues.
  # Gives the logged in User a new InfoRequest to contribute to.
  #
  # Subclasses must implement #info_requests.
  class Base
    def initialize(project, session)
      @project = project
      @session = session
    end

    def next
      find_and_remember_next
    end

    def skip(info_request)
      skipped << info_request.to_param
    end

    def include?(info_request)
      info_requests.include?(info_request)
    end

    def ==(other)
      project == other.project && session == other.session
    end

    protected

    attr_reader :project, :session

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
      unskipped_requests.find_by(id: current) if current
    end

    def sample
      unskipped_requests.sample
    end

    def remember_current(info_request)
      return queue['current'] = nil unless info_request
      queue['current'] = info_request.to_param
    end

    def current
      queue['current']
    end

    def skipped
      queue['skipped']
    end

    def queue
      prime_session
      session['projects'][project.to_param][queue_name]
    end

    def prime_session
      @prime_session ||= prime_session!
    end

    def prime_session!
      session['projects'] ||= {}
      session['projects'][project.to_param] ||= {}
      session['projects'][project.to_param][queue_name] ||= {}
      session['projects'][project.to_param][queue_name]['current'] ||= nil
      session['projects'][project.to_param][queue_name]['skipped'] ||= []
      true
    end

    # e.g: Project::Queue::Classifiable => "classifiable"
    def queue_name
      self.class.to_s.demodulize.underscore
    end

    def unskipped_requests
      info_requests.where.not(id: skipped)
    end

    def info_requests
      raise NotImplementedError
    end
  end
end
