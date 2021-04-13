##
# User survey methods for if given user should be asked to complete the survey
#
module User::Survey
  def survey
    return @survey if @survey
    @survey = MySociety::Survey.new(AlaveteliConfiguration.site_name, email)
  end

  def can_send_survey?
    active? && !survey.already_done?
  end
end
