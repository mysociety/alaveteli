class SurveyMailer::SurveyAlert < ActionMailer::Preview
  def survey_alert
    SurveyMailer.survey_alert(info_request)
  end

  private

  def info_request
    InfoRequest.new(
      title: 'A request',
      url_title: 'a_request',
      user: User.first,
      public_body: PublicBody.first
    )
  end
end
