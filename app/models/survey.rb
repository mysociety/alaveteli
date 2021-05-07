class Survey
  def self.enabled?
    AlaveteliConfiguration.survey_url.present?
  end
end
