##
# Export a project's info request classifications and data extractions to CSV.
#
class Project::Export
  require_dependency 'project/export/info_request'

  attr_reader :project
  protected :project

  def initialize(project)
    @project = project
  end

  def data
    @data ||= project.info_requests.extracted.map do |info_request|
      Project::Export::InfoRequest.new(project, info_request).data
    end
  end
end
