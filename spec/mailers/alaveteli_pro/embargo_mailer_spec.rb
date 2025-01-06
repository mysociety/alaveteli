require 'spec_helper'

RSpec.describe AlaveteliPro::EmbargoMailer do
  let(:pro_user) { FactoryBot.create(:pro_user) }
  let(:pro_user_2) { FactoryBot.create(:pro_user) }
  let(:embargo_extension) { FactoryBot.create(:embargo_extension) }

  let!(:expiring_1) do
    FactoryBot.create(:embargo_expiring_request, user: pro_user)
  end
  let!(:expiring_2) do
    FactoryBot.create(:embargo_expiring_request, user: pro_user)
  end
  let!(:expiring_3) do
    FactoryBot.create(:embargo_expiring_request, user: pro_user_2)
  end

  let!(:expired_1) do
    FactoryBot.create(:embargo_expired_request, user: pro_user)
  end
  let!(:expired_2) do
    FactoryBot.create(:embargo_expired_request, user: pro_user)
  end
  let!(:expired_3) do
    FactoryBot.create(:embargo_expired_request, user: pro_user_2)
  end

  let!(:embargoed) { FactoryBot.create(:embargoed_request) }
  let!(:not_embargoed) { FactoryBot.create(:info_request) }

  describe '.alert_expiring' do
    it 'only sends one email per user' do
      AlaveteliPro::EmbargoMailer.alert_expiring
      mails = ActionMailer::Base.deliveries
      expect(mails.size).to eq 2
      first_mail = mails.detect { |mail| mail.to == [pro_user.email] }
      second_mail = mails.detect { |mail| mail.to == [pro_user_2.email] }
      expect(first_mail).not_to be nil
      expect(second_mail).not_to be nil
    end

    it 'only sends an alert about an expiring embargo once' do
      AlaveteliPro::EmbargoMailer.alert_expiring
      expect(ActionMailer::Base.deliveries.size).to eq 2

      ActionMailer::Base.deliveries.clear
      AlaveteliPro::EmbargoMailer.alert_expiring
      expect(ActionMailer::Base.deliveries.size).to eq 0
    end

    it 'sends an alert about an expiring embargo extension' do
      AlaveteliPro::EmbargoMailer.alert_expiring
      expect(ActionMailer::Base.deliveries.size).to eq 2

      ActionMailer::Base.deliveries.clear
      expiring_3.embargo.extend(embargo_extension)
      travel_to(AlaveteliPro::Embargo.three_months_from_now - 3.days) do
        AlaveteliPro::EmbargoMailer.alert_expiring
        mails = ActionMailer::Base.deliveries
        expect(mails.detect { |mail| mail.to == [pro_user_2.email] }).
          not_to be_nil
      end
    end

    it 'creates UserInfoRequestSentAlert records for each expiring request' do
      expect(UserInfoRequestSentAlert.where(
        info_request_id: expiring_1.id,
        user_id: pro_user.id)
      ).not_to exist
      expect(UserInfoRequestSentAlert.where(
        info_request_id: expiring_2.id,
        user_id: pro_user.id)
      ).not_to exist
      expect(UserInfoRequestSentAlert.where(
        info_request_id: expiring_3.id,
        user_id: pro_user_2.id)
      ).not_to exist

      AlaveteliPro::EmbargoMailer.alert_expiring

      expect(UserInfoRequestSentAlert.where(
        info_request_id: expiring_1.id,
        user_id: pro_user.id)
      ).to exist
      expect(UserInfoRequestSentAlert.where(
        info_request_id: expiring_2.id,
        user_id: pro_user.id)
      ).to exist
      expect(UserInfoRequestSentAlert.where(
        info_request_id: expiring_3.id,
        user_id: pro_user_2.id)
      ).to exist
    end

    it "doesn't include requests with use_notifications: true" do
      pro_user_3 = FactoryBot.create(:pro_user)
      info_request = FactoryBot.create(
        :embargo_expiring_request,
        use_notifications: true,
        user: pro_user_3
      )

      AlaveteliPro::EmbargoMailer.alert_expiring

      mails = ActionMailer::Base.deliveries
      mail = mails.detect { |m| m.to == [pro_user_3.email] }
      expect(mail).to be nil
    end
  end

  describe '#expiring_alert' do
    context "when there's just one embargo" do
      before do
        @message = AlaveteliPro::EmbargoMailer.
                    expiring_alert(pro_user, [expiring_1]).
                      message
      end

      it 'sets the subject correctly for a single embargo' do
        expected_subject = '1 request will be made public on Alaveteli this week'
        expect(@message.subject).to eq expected_subject
      end

      context "when the user does not use default locale" do
        before do
          pro_user.locale = 'es'
          @message = AlaveteliPro::EmbargoMailer.
            expiring_alert(pro_user, [expiring_1]).
            message
        end

        it "translates the subject" do
          expect(@message.subject). to eq(
            "*** Spanish missing *** 1 *** Alaveteli"
          )
        end
      end

      it "sends the email to the user" do
        expect(@message.to).to eq [pro_user.email]
      end

      it "sends the email from the blackhole address" do
        expect(@message.from).to eq [blackhole_email]
      end
    end

    context "when there are multiple embargoes" do
      before do
        @message = AlaveteliPro::EmbargoMailer.
                     expiring_alert(pro_user, [expiring_1, expiring_2]).
                       message
      end

      it 'sets the subject correctly' do
        expected_subject = '2 requests will be made public on Alaveteli this week'
        expect(@message.subject).to eq expected_subject
      end

      context "when the user does not use default locale" do
        before do
          pro_user.locale = 'es'
          @message = AlaveteliPro::EmbargoMailer.
            expiring_alert(pro_user, [expiring_1, expiring_2]).
            message
        end

        it "translates the subject" do
          expect(@message.subject). to eq(
            "*** Spanish missings *** 2 *** Alaveteli"
          )
        end
      end

      it "sends the email to the user" do
        expect(@message.to).to eq [pro_user.email]
      end

      it "sends the email from the blackhole address" do
        expect(@message.from).to eq [blackhole_email]
      end
    end

    it "Doesn't escape characters in the site name in the subject line" do
      allow(AlaveteliConfiguration).
        to receive(:site_name).and_return("Something & something")
      @message = AlaveteliPro::EmbargoMailer.
        expiring_alert(pro_user, [expiring_1])
      escaped_subject = "1 request will be made public on Something &amp; " \
                        "something this week"
      expect(@message.subject).not_to eq escaped_subject
    end
  end

  describe '.alert_expired' do
    it 'only sends one email per user' do
      AlaveteliPro::EmbargoMailer.alert_expired
      mails = ActionMailer::Base.deliveries
      expect(mails.size).to eq 2
      first_mail = mails.detect { |mail| mail.to == [pro_user.email] }
      second_mail = mails.detect { |mail| mail.to == [pro_user_2.email] }
      expect(first_mail).not_to be nil
      expect(second_mail).not_to be nil
    end

    it 'only sends an alert about an expired embargo once' do
      AlaveteliPro::EmbargoMailer.alert_expired
      expect(ActionMailer::Base.deliveries.size).to eq 2

      ActionMailer::Base.deliveries.clear
      AlaveteliPro::EmbargoMailer.alert_expired
      expect(ActionMailer::Base.deliveries.size).to eq 0
    end

    it 'creates UserInfoRequestSentAlert records for each expired request' do
      expect(UserInfoRequestSentAlert.where(
        info_request_id: expired_1.id,
        user_id: pro_user.id)
      ).not_to exist

      expect(UserInfoRequestSentAlert.where(
        info_request_id: expired_2.id,
        user_id: pro_user.id)
      ).not_to exist

      expect(UserInfoRequestSentAlert.where(
        info_request_id: expired_3.id,
        user_id: pro_user_2.id)
      ).not_to exist

      AlaveteliPro::EmbargoMailer.alert_expired

      expect(UserInfoRequestSentAlert.where(
        info_request_id: expired_1.id,
        user_id: pro_user.id)
      ).to exist

      expect(UserInfoRequestSentAlert.where(
        info_request_id: expired_2.id,
        user_id: pro_user.id)
      ).to exist

      expect(UserInfoRequestSentAlert.where(
        info_request_id: expired_3.id,
        user_id: pro_user_2.id)
      ).to exist
    end

    it "doesn't include requests with use_notifications: true" do
      pro_user_3 = FactoryBot.create(:pro_user)
      info_request = FactoryBot.create(
        :embargo_expired_request,
        use_notifications: true,
        user: pro_user_3
      )

      AlaveteliPro::EmbargoMailer.alert_expired

      mails = ActionMailer::Base.deliveries
      mail = mails.detect { |m| m.to == [pro_user_3.email] }
      expect(mail).to be nil
    end
  end

  describe '#expired_alert' do
    context "when there's just one embargo" do
      before do
        @message = AlaveteliPro::EmbargoMailer.
                    expired_alert(pro_user, [expired_1]).
                      message
      end

      it 'sets the subject correctly for a single embargo' do
        expected = '1 request has been made public on Alaveteli'
        expect(@message.subject).to eq expected
      end

      context "when the user does not use default locale" do
        before do
          pro_user.locale = 'es'
          @message = AlaveteliPro::EmbargoMailer.
            expired_alert(pro_user, [expired_1]).
            message
        end

        it "translates the subject" do
          expect(@message.subject). to eq(
            "*** Spanish missing *** 1 *** Alaveteli"
          )
        end
      end

      it "sends the email to the user" do
        expect(@message.to).to eq [pro_user.email]
      end

      it "sends the email from the blackhole address" do
        expect(@message.from).to eq [blackhole_email]
      end
    end

    context "when there are multiple embargoes" do
      before do
        @message = AlaveteliPro::EmbargoMailer.
                     expired_alert(pro_user, [expired_1, expired_2]).
                       message
      end

      it 'sets the subject correctly' do
        expected = '2 requests have been made public on Alaveteli'
        expect(@message.subject).to eq expected
      end

      context "when the user does not use default locale" do
        before do
          pro_user.locale = 'es'
          @message = AlaveteliPro::EmbargoMailer.
            expired_alert(pro_user, [expired_1, expired_2]).
            message
        end

        it "translates the subject" do
          expect(@message.subject). to eq(
            "*** Spanish missings *** 2 *** Alaveteli"
          )
        end
      end

      it "sends the email to the user" do
        expect(@message.to).to eq [pro_user.email]
      end

      it "sends the email from the blackhole address" do
        expect(@message.from).to eq [blackhole_email]
      end
    end
  end
end
