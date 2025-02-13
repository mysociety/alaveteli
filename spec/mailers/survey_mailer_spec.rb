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
      info_request.created_at = 1.month.ago
      info_request.save!
      info_request
    end

    context 'when there is a requester who has not been sent a survey alert' do
      it 'sends a survey alert' do
        get_surveyable_request
        SurveyMailer.alert_survey
        expect(ActionMailer::Base.deliveries.size).to eq(1)
      end

      it "sends a mail with correct subject" do
        info_request = get_surveyable_request
        SurveyMailer.alert_survey
        mail = ActionMailer::Base.deliveries.first
        expect(mail.subject). to eq(
          "A survey about your recent Freedom of Information request"
        )
      end

      it 'records the sending of the alert' do
        info_request = get_surveyable_request
        SurveyMailer.alert_survey
        expect(info_request.user.user_info_request_sent_alerts.size).
          to eq(1)
      end

      context "when the user does not use default locale" do
        before do
          @info_request = get_surveyable_request(
            FactoryBot.create(:user, locale: 'es')
          )
          SurveyMailer.alert_survey
        end

        it "translates the subject" do
          mail = ActionMailer::Base.deliveries.first
          expect(mail.subject). to eq(
            "*** Spanish missing ***"
          )
        end
      end
    end

    context 'when a user has made multiple qualifying requests' do
      it 'does not send multiple alerts' do
        request = get_surveyable_request
        get_surveyable_request(request.user)
        SurveyMailer.alert_survey
        expect(ActionMailer::Base.deliveries.size).to eq(1)
      end
    end

    context 'when a user can not be sent the survey' do
      it 'does not send a survey alert' do
        allow_any_instance_of(User).to receive(:can_send_survey?).
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
