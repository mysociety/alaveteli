# Public: Classifiable requests in the given Project for the given User.
class Project::Queue::Classifiable < Project::Queue
  def info_requests
    project.info_requests.classifiable
  end
end
