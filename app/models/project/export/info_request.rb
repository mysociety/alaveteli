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
      classified_by: classification_contributor&.name,
      classified_by_url:
        (user_url(classification_contributor) if classification_contributor),
      status: InfoRequest.get_status_description(described_state),
      extracted_by: dataset_contributor&.name,
      extracted_by_url: (user_url(dataset_contributor) if dataset_contributor),
      info_request: __getobj__,
      classification_resource: last_status_update_event,
      extraction_resource: extraction_submission&.resource
    }.merge(dataset_values)
  end

  private

  def submissions
    project.submissions.where(info_request: id)
  end

  def classification_submission
    submissions.classification.last
  end

  def last_status_update_event
    info_request_events.where(event_type: 'status_update').last
  end

  def classification_is_latest_status_update?
    return false unless classification_submission && last_status_update_event

    classification_submission.resource == last_status_update_event
  end

  def extraction_submission
    submissions.extraction.last
  end

  def classification_contributor
    return unless classification_is_latest_status_update?

    classification_submission.user
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

    extraction_submission.resource.values.preload(:key)
  end

  def extracted_values_as_hash
    return {} unless extracted_values

    extracted_values.each_with_object({}) do |extracted, acc|
      acc[extracted.title] = extracted.mapped_value
    end
  end
end
