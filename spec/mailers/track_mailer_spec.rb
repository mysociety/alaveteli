require 'spec_helper'

RSpec.describe TrackMailer do
  describe '.alert_tracks' do
    subject { described_class.alert_tracks }

    let(:user) do
      user = FactoryBot.create(:user,
                               name: 'test',
                               url_name: 'test-name',
                               last_daily_track_email: 2.days.ago,
                               updated_at: 1.day.ago)
      user.no_xapian_reindex = false
      request = FactoryBot.create(:info_request)
      FactoryBot.create(:track_thing,
                        tracking_user: user,
                        info_request_id: request.id)
      user
    end

    before do
      mail_mock = double("mail")
      allow(mail_mock).to receive(:deliver_now)
      allow(TrackMailer).to receive(:event_digest).and_return(mail_mock)
      allow(Time).to receive(:now).and_return(Time.utc(2007, 11, 12, 23, 59))
      update_xapian_index
    end

    it 'asks for all the users whose last daily track email was sent more than a day ago' do
      expected_conditions = [ "last_daily_track_email < ?", Time.utc(2007, 11, 11, 23, 59)]
      expect(User).
        to receive(:where).with(expected_conditions).and_call_original
      subject
    end

    describe 'for each user' do
      before do
        allow(User).to receive_message_chain(:where, :find_each).and_yield(user)
        allow(user).to receive(:receive_email_alerts).and_return(true)
        allow(user).to receive(:no_xapian_reindex=)
      end

      it 'asks for any daily track things for the user' do
        expected_conditions = {
          tracking_user_id: user.id,
          track_medium: 'email_daily'
        }
        expect(TrackThing).
          to receive(:where).with(expected_conditions).and_return([])
        subject
      end

      it 'sets the no_xapian_reindex flag on the user' do
        expect(user).to receive(:no_xapian_reindex=).with(true)
        subject
      end

      it "updates the time of the user's last daily tracking email" do
        expect(user).to receive(:last_daily_track_email=).with(Time.zone.now)
        expect(user).to receive(:save!).with(touch: false)
        subject
      end

      it "does not update the user's last updated timestamp" do
        expect {
          subject
          user.reload
        }.to_not change(user, :updated_at)
      end

      it { is_expected.to eq(true) }

      describe 'for each tracked thing' do
        before do
          @track_things_sent_emails_array = []
          allow(@track_things_sent_emails_array).to receive(:where).and_return([]) # this is for the date range find (created in last 14 days)
          @track_thing = mock_model(TrackThing, track_query: 'test query',
                                    track_things_sent_emails: @track_things_sent_emails_array,
                                    created_at: Time.utc(2007, 11, 9, 23, 59))
          allow(TrackThing).to receive(:where).and_return([@track_thing])
          @track_things_sent_email = mock_model(TrackThingsSentEmail, :save! => true,
                                                :track_thing_id= => true,
                                                :info_request_event_id= => true)
          allow(TrackThingsSentEmail).to receive(:new).and_return(@track_things_sent_email)
          @xapian_search = double('xapian search', results: [])
          @found_event = mock_model(InfoRequestEvent, described_at: @track_thing.created_at + 1.day)
          @search_result = { model: @found_event }
          allow(ActsAsXapian::Search).to receive(:new).and_return(@xapian_search)
        end

        it 'should ask for the events returned by the tracking query' do
          expect(ActsAsXapian::Search).to receive(:new).with([InfoRequestEvent], 'test query',
                                                         sort_by_prefix: 'described_at',
                                                         sort_by_ascending: true,
                                                         collapse_by_prefix: nil,
                                                         limit: 100).and_return(@xapian_search)
          TrackMailer.alert_tracks
        end

        it 'should not include in the email any events that the user has already been sent a tracking email about' do
          sent_email = mock_model(TrackThingsSentEmail, info_request_event_id: @found_event.id)
          allow(@track_things_sent_emails_array).to receive(:where).and_return([sent_email]) # this is for the date range find (created in last 14 days)
          allow(@xapian_search).to receive(:results).and_return([@search_result])
          expect(TrackMailer).not_to receive(:event_digest)
          TrackMailer.alert_tracks
        end

        it 'should not include in the email any events not sent in a previous tracking email that were described before the track was set up' do
          allow(@found_event).to receive(:described_at).and_return(@track_thing.created_at - 1.day)
          allow(@xapian_search).to receive(:results).and_return([@search_result])
          expect(TrackMailer).not_to receive(:event_digest)
          TrackMailer.alert_tracks
        end

        it 'should include in the email any events that the user has not been sent a tracking email on that have been described since the track was set up' do
          allow(@found_event).to receive(:described_at).and_return(@track_thing.created_at + 1.day)
          allow(@xapian_search).to receive(:results).and_return([@search_result])
          expect(TrackMailer).to receive(:event_digest)
          TrackMailer.alert_tracks
        end

        it 'should raise an error if a non-event class is returned by the tracking query' do
          allow(@xapian_search).to receive(:results).and_return([{ model: 'string class' }])
          expect { TrackMailer.alert_tracks }.to raise_error('need to add other types to TrackMailer.alert_tracks (unalerted)')
        end

        it 'should record that a tracking email has been sent for each event that
            has been included in the email' do
          allow(@xapian_search).to receive(:results).and_return([@search_result])
          sent_email = mock_model(TrackThingsSentEmail)
          expect(TrackThingsSentEmail).to receive(:new).and_return(sent_email)
          expect(sent_email).to receive(:track_thing_id=).with(@track_thing.id)
          expect(sent_email).to receive(:info_request_event_id=).with(@found_event.id)
          expect(sent_email).to receive(:save!)
          TrackMailer.alert_tracks
        end
      end
    end

    describe 'when a user should not be emailed' do
      before do
        allow(User).to receive_message_chain(:where, :find_each).and_yield(user)
        allow(user).to receive(:should_be_emailed?).and_return(false)
        allow(user).to receive(:receive_email_alerts).and_return(true)
        allow(user).to receive(:no_xapian_reindex=)
      end

      it 'does not ask for any daily track things for the user' do
        expected_conditions =
          ['tracking_user_id = ? and track_medium = ?', user.id, 'email_daily']
        expect(TrackThing).
          not_to receive(:find).with(:all, conditions: expected_conditions)
        subject
      end

      it 'does not ask for any daily track things for the user if they have receive_email_alerts off but could otherwise be emailed' do
        allow(user).to receive(:should_be_emailed?).and_return(true)
        allow(user).to receive(:receive_email_alerts).and_return(false)
        expected_conditions =
          ['tracking_user_id = ? and track_medium = ?', user.id, 'email_daily']
        expect(TrackThing).
          not_to receive(:find).with(:all, conditions: expected_conditions)
        subject
      end

      it 'does not set the no_xapian_reindex flag on the user' do
        expect(user).not_to receive(:no_xapian_reindex=).with(true)
        subject
      end

      it 'does not update the time of the user\'s last daily tracking email' do
        expect(user).
          not_to receive(:last_daily_track_email=).with(Time.zone.now)
        expect(user).not_to receive(:save!)
        subject
      end

      it { is_expected.to eq(false) }
    end
  end

  describe 'delivering the email' do
    before :each do
      allow(AlaveteliConfiguration).to receive(:site_name).
        and_return("L'information")
      @post_redirect = mock_model(PostRedirect, save!: true,
                                  email_token: "token")
      allow(PostRedirect).to receive(:new).and_return(@post_redirect)
      ActionMailer::Base.deliveries = []
      @user = mock_model(User,
                         name_and_email: MailHandler.address_from_name_and_email('Tippy Test', 'tippy@localhost'),
                         url_name: 'tippy_test',
                         locale: 'es'
                         )
      TrackMailer.event_digest(@user, []).deliver_now # no items in it email for minimal test
    end

    it 'should deliver one email, with right headers' do
      deliveries = ActionMailer::Base.deliveries
      if deliveries.size > 1 # debugging if there is an error
        deliveries.each do |d|
          $stderr.puts "------------------------------"
          $stderr.puts d.body
          $stderr.puts "------------------------------"
        end
      end
      expect(deliveries.size).to eq(1)
      mail = deliveries[0]

      expect(mail['Auto-Submitted'].to_s).to eq('auto-generated')
      expect(mail['Precedence'].to_s).to eq('bulk')

      deliveries.clear
    end

    it "does not include HTMLEntities in the subject line" do
      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(1)
      mail = deliveries[0]
      expect(mail.subject).to eq "Tu alerta en L'information"
    end

    it "translates the subject for a user with non-default locale" do
      # Yes, this is indeed just the same test as above. We simply give the
      # user a non-default locale in the "before". Use let bindings instead?
      expect(ActionMailer::Base.deliveries[0].subject).
        to eq "Tu alerta en L'information"
    end

    it "does not alert about embargoed requests" do
      info_request = FactoryBot.create(:embargoed_request)
      user = FactoryBot.create(
        :user,
        last_daily_track_email: Time.zone.now - 2.days)
      track_thing = FactoryBot.create(
        :public_body_track,
        public_body: info_request.public_body,
        tracking_user: user)
      info_request.log_event(
        'sent',
        outgoing_message_id: info_request.outgoing_messages.first.id,
        email: info_request.public_body.request_email
      )

      ActionMailer::Base.deliveries.clear
      update_xapian_index
      TrackMailer.alert_tracks

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(0)
      mail = deliveries[0]
    end

    context "force ssl is off" do
      # Force SSL is off in the tests. Since the code that selectively switches the protocols
      # is in the initialiser for Rails it's hard to test. Hmmm...
      # We could AlaveteliConfiguration.stub(:force_ssl).and_return(true) but the config/environment.rb
      # wouldn't get reloaded

      it "should have http links in the email" do
        deliveries = ActionMailer::Base.deliveries
        expect(deliveries.size).to eq(1)
        mail = deliveries[0]

        expect(mail.body).to include("http://")
        expect(mail.body).not_to include("https://")
      end
    end
  end
end
