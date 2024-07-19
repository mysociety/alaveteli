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
      request: title,
      request_url: request_url(self),
      requested_by: user&.name,
      requested_by_url: user_url(user),
      public_body: public_body.name,
      public_body_url: public_body_url(public_body),
      classified_by: status_contributor&.name,
      classified_by_url: (user_url(status_contributor) if status_contributor),
      classification: described_state,
      extracted_by: dataset_contributor&.name,
      extracted_by_url: (user_url(dataset_contributor) if dataset_contributor)
    }.merge(dataset_values)
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
    return project.owner unless status_submission

    status_submission.user
  end

  def dataset_contributor
    return unless extraction_submission

    extraction_submission.user
  end

  def dataset_values
    project.key_set.keys.pluck(:title).each_with_object({}) do |key, memo|
      memo[key] = extracted_values_as_hash[key]
    end
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
