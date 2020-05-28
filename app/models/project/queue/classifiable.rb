class Project::Queue::Classifiable < Project::Queue
  def info_requests
    project.info_requests.classifiable
  end
end
