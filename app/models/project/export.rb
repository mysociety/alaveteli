##
# Export a project's info request classifications and data extractions to CSV.
#
class Project::Export
  require_dependency 'project/export/info_request'

  include DownloadHelper

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

  def name
    generate_download_filename(
      resource: 'project',
      id: project.id,
      title: project.title,
      ext: 'csv'
    )
  end

  def to_csv
    CSV.generate do |csv|
      header = data.first
      csv << header.keys.map(&:to_s) if header
      data.each { |row| csv << row.values }
    end
  end
end
