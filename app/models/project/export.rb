##
# Export a project's info request classifications and data extractions to CSV.
#
class Project::Export
  require_dependency 'project/export/info_request'

  include DownloadHelper
  include ActionView::Helpers::TagHelper

  attr_reader :project
  protected :project

  def initialize(project)
    @project = project
  end

  def data
    @data ||= project.info_requests.map do |info_request|
      Project::Export::InfoRequest.new(project, info_request).data
    end
  end

  def data_for_web
    @data_for_web ||= data_for_csv.map do |row|
      row.each_with_object({}) do |(key, value), obj|
        if key.to_s.end_with?('_url')
          base_key = key.to_s.sub('_url', '').to_sym
          next obj unless row[base_key]

          value = tag.a(row[base_key], href: value)
        end

        obj[base_key || key] = value
      end
    end
  end

  def data_for_csv
    @data_for_csv ||= data.map do |row|
      row.except(
        :info_request,
        :key_set,
        :classification_resource,
        :extraction_resource
      )
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
      header = data_for_csv.first
      csv << header.keys.map(&:to_s) if header
      data_for_csv.each { |row| csv << row.values }
    end
  end
end
