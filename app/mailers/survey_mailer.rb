##
# Mailer to deliver a survey to users who have recently made a request for
# information
#
class SurveyMailer < ApplicationMailer
  include AlaveteliFeatures::Helpers

  before_action :set_footer_template

  def survey_alert(info_request)
    user = info_request.user

    post_redirect = PostRedirect.new(
      uri: survey_url,
      user_id: user.id
    )
    post_redirect.save!
    @url = confirm_url(email_token: post_redirect.email_token)
    @info_request = info_request

    headers(
      'Return-Path' => blackhole_email,
      'Reply-To' => contact_from_name_and_email,
      'Auto-Submitted' => 'auto-generated',
      'X-Auto-Response-Suppress' => 'OOF'
    )

    mail(
      to: user.name_and_email,
      from: contact_from_name_and_email,
      subject: 'Can you help us improve WhatDoTheyKnow?'
    )
  end

  # Send an email with a link to the survey two weeks after a request was made,
  # if the user has not already completed the survey.
  def self.alert_survey
    return unless AlaveteliConfiguration.send_survey_mails

    # Exclude requests made by users who have already been alerted about the
    # survey
    info_requests = InfoRequest.where(
      <<~SQL
        created_at BETWEEN
          NOW() - '2 weeks + 1 day'::interval AND
          NOW() - '2 weeks'::interval
        AND user_id IS NOT NULL
        AND NOT EXISTS (
            SELECT *
            FROM user_info_request_sent_alerts
            WHERE user_id = info_requests.user_id
            AND alert_type = 'survey_1'
        )
      SQL
    ).includes(:user)

    # TODO: change the initial query to iterate over users rather
    # than info_requests rather than using an array to check whether
    # we're about to send multiple emails to the same user_id
    sent_to = []
    info_requests.each do |info_request|
      # Exclude users who have already completed the survey or
      # have already been sent a survey email in this run
      logger.debug "[alert_survey] Considering #{info_request.user.url_name}"
      if !info_request.user.can_send_survey? ||
         sent_to.include?(info_request.user_id)
        next
      end

      store_sent = UserInfoRequestSentAlert.new
      store_sent.info_request = info_request
      store_sent.user = info_request.user
      store_sent.alert_type = 'survey_1'
      store_sent.info_request_event_id = info_request.info_request_events[0].id

      sent_to << info_request.user_id

      SurveyMailer.survey_alert(info_request).deliver_now
      store_sent.save!
    end
  end

  private

  def set_footer_template
    @footer_template = 'default'
  end
end
