require 'spec_helper'

RSpec.describe User do
  describe '#survey_recently_sent?' do
    subject { user.survey_recently_sent? }

    let(:user) { FactoryBot.build(:user) }

    context 'user was sent the survey in the last year' do
      before do
        FactoryBot.create(
          :user_info_request_sent_alert,
          user: user, alert_type: 'survey_1', created_at: 1.year.ago
        )
      end

      it { is_expected.to eq true }
    end

    context 'user was sent the survey over a year ago' do
      before do
        FactoryBot.create(
          :user_info_request_sent_alert,
          user: user, alert_type: 'survey_1', created_at: 366.days.ago
        )
      end

      it { is_expected.to eq false }
    end

    context 'user was never sent the survey' do
      before { user.save }
      it { is_expected.to eq false }
    end
  end

  describe '#can_send_survey?' do
    subject { user.can_send_survey? }

    let(:user) { FactoryBot.build(:user) }

    context 'a survey has not been sent recently to an active user' do
      before do
        allow(user).to receive(:survey_recently_sent?).and_return(false)
      end

      it { is_expected.to eq true }
    end

    context 'a survey was recently sent' do
      before do
        allow(user).to receive(:survey_recently_sent?).and_return(true)
      end

      it { is_expected.to eq false }
    end

    context 'the user is not active' do
      before do
        allow(user).to receive(:active?).and_return(false)
      end

      it { is_expected.to eq false }
    end
  end
end
