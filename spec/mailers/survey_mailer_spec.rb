require 'spec_helper'

RSpec.describe SurveyMailer do

  describe 'survey alerts' do

    before do
      allow(Survey).to receive(:enabled?).and_return(true)
      InfoRequest.destroy_all
      ActionMailer::Base.deliveries = []
    end

    def get_surveyable_request(user = nil)
      info_request = if user
                       FactoryBot.create(:info_request, user: user)
                     else
                       FactoryBot.create(:info_request)
                     end
      info_request.created_at = Time.now - (2.weeks + 1.hour)
      info_request.save!
      info_request
    end

    context 'when there is a requester who has not been sent a survey alert' do

      it 'sends a survey alert' do
        allow_any_instance_of(User).to receive(:survey).
          and_return(double('survey', already_done?: false))
        get_surveyable_request
        SurveyMailer.alert_survey
        expect(ActionMailer::Base.deliveries.size).to eq(1)
      end

      it 'records the sending of the alert' do
        allow_any_instance_of(User).to receive(:survey).
          and_return(double('survey', already_done?: false))
        info_request = get_surveyable_request
        SurveyMailer.alert_survey
        expect(info_request.user.user_info_request_sent_alerts.size).
          to eq(1)
      end

    end

    context 'when there is a requester who has been sent a survey alert' do

      it 'does not send a survey alert' do
        allow_any_instance_of(User).to receive(:survey).
          and_return(double('survey', already_done?: false))
        info_request = get_surveyable_request
        info_request.user.user_info_request_sent_alerts.
          create(alert_type: 'survey_1',
                 info_request_id: info_request.id)
        SurveyMailer.alert_survey
        expect(ActionMailer::Base.deliveries.size).to eq(0)
      end

    end

    context 'when there is a requester who has previously filled in the survey' do

      it 'does not send a survey alert' do
        allow_any_instance_of(User).to receive(:survey).
          and_return(double('survey', already_done?: true))
        get_surveyable_request
        SurveyMailer.alert_survey
        expect(ActionMailer::Base.deliveries.size).to eq(0)
      end
    end

    context 'when a user has made multiple qualifying requests' do

      it 'does not send multiple alerts' do
        allow_any_instance_of(User).to receive(:survey).
          and_return(double('survey', already_done?: false))
        request = get_surveyable_request
        get_surveyable_request(request.user)
        SurveyMailer.alert_survey
        expect(ActionMailer::Base.deliveries.size).to eq(1)
      end
    end

    context 'when a user is inactive' do

      it 'does not send a survey alert' do
        allow_any_instance_of(User).to receive(:survey).
          and_return(double('survey', already_done?: false))
        allow_any_instance_of(User).to receive(:active?).
          and_return(false)
        get_surveyable_request
        SurveyMailer.alert_survey
        expect(ActionMailer::Base.deliveries.size).to eq(0)
      end

    end

    context 'when survery is not enabled' do

      before do
        allow(Survey).to receive(:enabled?).and_return(false)
      end

      it 'does not send survey alerts ' do
        expect(SurveyMailer.alert_survey).to be_nil
      end

    end

  end

end
