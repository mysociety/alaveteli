##
# User survey methods for if given user should be asked to complete the survey
#
module User::Survey
  def survey_recently_sent?
    user_info_request_sent_alerts.where(alert_type: 'survey_1').recent.any?
  end

  def can_send_survey?
    active? && !survey_recently_sent?
  end
end
