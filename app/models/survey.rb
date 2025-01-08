##
# Class responsible for generating URLs to user survey. Base URL configured at
# the SURVEY_URL option. We append an `authority_id` query parameter if the user
# in question isn't obviously identifiable - EG if more then 10 other requesters
# have requests to the same PublicBody
#
class Survey
  include LinkToHelper

  def self.enabled?
    url.present?
  end

  def self.url
    AlaveteliConfiguration.survey_url
  end

  def self.date_range
    period = 1.month
    period.ago.at_beginning_of_day..period.ago.at_end_of_day
  end

  def initialize(public_body)
    @public_body = public_body
  end

  def url
    return Survey.url if user_too_identifiable?

    add_query_params_to_url(Survey.url, authority_id: public_body)
  end

  protected

  attr_reader :public_body

  private

  def user_too_identifiable?
    User.distinct.joins(:info_requests).
      where(info_requests: { public_body: public_body }).
      count < 10
  end
end
