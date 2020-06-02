module Project::Queue
  # Stores state for a Project::Queue in the session
  class SessionBackend
    def self.primed(session, project, queue_name)
      project_id = project.to_param
      queue_name = queue_name.to_s

      session['projects'] ||= {}
      session['projects'][project_id] ||= {}
      session['projects'][project_id][queue_name] ||= {}
      session['projects'][project_id][queue_name]['current'] ||= nil
      session['projects'][project_id][queue_name]['skipped'] ||= []

      new(session, project_id: project_id, queue_name: queue_name)
    end

    def initialize(session, project_id:, queue_name:)
      @session = session
      @project_id = project_id
      @queue_name = queue_name
    end

    def current=(id)
      queue['current'] = id.to_param
    end

    def current
      queue['current']
    end

    def clear_current
      queue['current'] = nil
    end

    def skip(id)
      skipped << id.to_param
    end

    def skipped
      queue['skipped']
    end

    def clear_skipped
      skipped.clear
    end

    def ==(other)
      session == other.session &&
        project_id == other.project_id &&
        queue_name == other.queue_name
    end

    protected

    attr_reader :session, :project_id, :queue_name

    private

    def queue
      session['projects'][project_id][queue_name]
    end
  end
end

