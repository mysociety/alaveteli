class Survey
  def self.enabled?
    AlaveteliConfiguration.survey_url.present?
  end

  def self.date_range
    period = 2.weeks
    period.ago.at_beginning_of_day..period.ago.at_end_of_day
  end
end
