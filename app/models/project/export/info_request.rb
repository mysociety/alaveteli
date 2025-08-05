##
# Export key classification and extracted data for an info request within a
# given project.
#
class Project::Export::InfoRequest < SimpleDelegator
  include Rails.application.routes.url_helpers
  include LinkToHelper
  default_url_options[:host] = AlaveteliConfiguration.domain

  attr_reader :project
  protected :project

  def initialize(project, info_request)
    @project = project
    super(info_request)
  end

  def data
    {
      request_url: request_url(self),
      request_title: title,
      public_body_name: public_body.name,
      request_owner: user&.name,
      latest_status_contributor: status_contributor,
      status: described_state,
      dataset_contributor: dataset_contributor
    }.merge(extracted_values_as_hash)
  end

  private

  def submissions
    project.submissions.where(info_request: id)
  end

  def status_submission
    submissions.classification.last
  end

  def extraction_submission
    submissions.extraction.last
  end

  def status_contributor
    return project.owner.name unless status_submission
    status_submission.user.name
  end

  def dataset_contributor
    return unless extraction_submission
    extraction_submission.user.name
  end

  def extracted_values
    return unless extraction_submission
    extraction_submission.resource.values
  end

  def extracted_values_as_hash
    return {} unless extracted_values
    extracted_values.joins(:key).pluck('dataset_keys.title', :value).to_h
  end
end
