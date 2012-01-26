require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe TrackMailer do

    describe 'when sending email alerts for tracked things' do

        before do
            TrackMailer.stub!(:deliver_event_digest)
            Time.stub!(:now).and_return(Time.utc(2007, 11, 12, 23, 59))
        end

        it 'should ask for all the users whose last daily track email was sent more than a day ago' do
            expected_conditions = [ "last_daily_track_email < ?", Time.utc(2007, 11, 11, 23, 59)]
            User.should_receive(:find).with(:all, :conditions => expected_conditions).and_return([])
            TrackMailer.alert_tracks
        end

        describe 'for each user' do

            before do
                @user = mock_model(User, :no_xapian_reindex= => false,
                                         :last_daily_track_email= => true,
                                         :save! => true,
                                         :url_name => 'test-name',
                                         :get_locale => 'en',
                                         :should_be_emailed? => true)
                User.stub!(:find).and_return([@user])
                @user.stub!(:no_xapian_reindex=)
            end

            it 'should ask for any daily track things for the user' do
                expected_conditions = [ "tracking_user_id = ? and track_medium = ?", @user.id, 'email_daily' ]
                TrackThing.should_receive(:find).with(:all, :conditions => expected_conditions).and_return([])
                TrackMailer.alert_tracks
            end


            it 'should set the no_xapian_reindex flag on the user' do
                @user.should_receive(:no_xapian_reindex=).with(true)
                TrackMailer.alert_tracks
            end

            it 'should update the time of the user\'s last daily tracking email' do
                @user.should_receive(:last_daily_track_email=).with(Time.now)
                @user.should_receive(:save!)
                TrackMailer.alert_tracks
            end
            it 'should return true' do
                TrackMailer.alert_tracks.should == true
            end


            describe 'for each tracked thing' do

                before do
                    @track_things_sent_emails_array = []
                    @track_things_sent_emails_array.stub!(:find).and_return([]) # this is for the date range find (created in last 14 days)
                    @track_thing = mock_model(TrackThing, :track_query => 'test query',
                                                          :track_things_sent_emails => @track_things_sent_emails_array,
                                                          :created_at => Time.utc(2007, 11, 9, 23, 59))
                    TrackThing.stub!(:find).and_return([@track_thing])
                    @track_things_sent_email = mock_model(TrackThingsSentEmail, :save! => true,
                                                                                :track_thing_id= => true,
                                                                                :info_request_event_id= => true)
                    TrackThingsSentEmail.stub!(:new).and_return(@track_things_sent_email)
                    @xapian_search = mock('xapian search', :results => [])
                    @found_event = mock_model(InfoRequestEvent, :described_at => @track_thing.created_at + 1.day)
                    @search_result = {:model => @found_event}
                    InfoRequest.stub!(:full_search).and_return(@xapian_search)
                end

                it 'should ask for the events returned by the tracking query' do
                    InfoRequest.should_receive(:full_search).with([InfoRequestEvent], 'test query', 'described_at', true, nil, 100, 1).and_return(@xapian_search)
                    TrackMailer.alert_tracks
                end

                it 'should not include in the email any events that the user has already been sent a tracking email about' do
                    sent_email = mock_model(TrackThingsSentEmail, :info_request_event_id => @found_event.id)
                    @track_things_sent_emails_array.stub!(:find).and_return([sent_email]) # this is for the date range find (created in last 14 days)
                    @xapian_search.stub!(:results).and_return([@search_result])
                    TrackMailer.should_not_receive(:deliver_event_digest)
                    TrackMailer.alert_tracks
                end

                it 'should not include in the email any events not sent in a previous tracking email that were described before the track was set up' do
                    @found_event.stub!(:described_at).and_return(@track_thing.created_at - 1.day)
                    @xapian_search.stub!(:results).and_return([@search_result])
                    TrackMailer.should_not_receive(:deliver_event_digest)
                    TrackMailer.alert_tracks
                end

                it 'should include in the email any events that the user has not been sent a tracking email on that have been described since the track was set up' do
                    @found_event.stub!(:described_at).and_return(@track_thing.created_at + 1.day)
                    @xapian_search.stub!(:results).and_return([@search_result])
                    TrackMailer.should_receive(:deliver_event_digest)
                    TrackMailer.alert_tracks
                end

                it 'should raise an error if a non-event class is returned by the tracking query' do
                    @xapian_search.stub!(:results).and_return([{:model => 'string class'}])
                    lambda{ TrackMailer.alert_tracks }.should raise_error('need to add other types to TrackMailer.alert_tracks (unalerted)')
                end

                it 'should record that a tracking email has been sent for each event that has been included in the email' do
                    @xapian_search.stub!(:results).and_return([@search_result])
                    sent_email = mock_model(TrackThingsSentEmail)
                    TrackThingsSentEmail.should_receive(:new).and_return(sent_email)
                    sent_email.should_receive(:track_thing_id=).with(@track_thing.id)
                    sent_email.should_receive(:info_request_event_id=).with(@found_event.id)
                    sent_email.should_receive(:save!)
                    TrackMailer.alert_tracks
                end
            end

        end

        describe 'when a user should not be emailed' do
            before do
                @user = mock_model(User, :no_xapian_reindex= => false,
                                         :last_daily_track_email= => true,
                                         :save! => true,
                                         :url_name => 'test-name',
                                         :should_be_emailed? => false)
                User.stub!(:find).and_return([@user])
                @user.stub!(:no_xapian_reindex=)
            end

            it 'should not ask for any daily track things for the user' do
                expected_conditions = [ "tracking_user_id = ? and track_medium = ?", @user.id, 'email_daily' ]
                TrackThing.should_not_receive(:find).with(:all, :conditions => expected_conditions).and_return([])
                TrackMailer.alert_tracks
            end


            it 'should not set the no_xapian_reindex flag on the user' do
                @user.should_not_receive(:no_xapian_reindex=).with(true)
                TrackMailer.alert_tracks
            end

            it 'should not update the time of the user\'s last daily tracking email' do
                @user.should_not_receive(:last_daily_track_email=).with(Time.now)
                @user.should_not_receive(:save!)
                TrackMailer.alert_tracks
            end
            it 'should return false' do
                TrackMailer.alert_tracks.should == false
            end
        end

    end

    describe 'delivering the email' do

        before do
          @post_redirect = mock_model(PostRedirect, :save! => true,
                                                    :email_token => "token")
          PostRedirect.stub!(:new).and_return(@post_redirect)
          ActionMailer::Base.deliveries = []
        end

        it 'should deliver one email, with right headers' do
            @user = mock_model(User,
                    :name_and_email => TMail::Address.address_from_name_and_email('Tippy Test', 'tippy@localhost'),
                    :url_name => 'tippy_test'
            )

            TrackMailer.deliver_event_digest(@user, []) # no items in it email for minimal test
            deliveries = ActionMailer::Base.deliveries
            if deliveries.size > 1 # debugging if there is an error
                deliveries.each do |d|
                    $stderr.puts "------------------------------"
                    $stderr.puts d.body
                    $stderr.puts "------------------------------"
                end
            end
            deliveries.size.should == 1
            mail = deliveries[0]

            mail['Auto-Submitted'].to_s.should == 'auto-generated'
            mail['Precedence'].to_s.should == 'bulk'

            deliveries.clear
        end
    end

end



