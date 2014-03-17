require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe TrackHelper do

    include TrackHelper
    include LinkToHelper

    describe 'when displaying notices for a search track' do

        before do
            @track_thing = FactoryGirl.build(:search_track)
        end

        it 'should create an already subscribed_notice' do
            expected = %Q(You are already subscribed to <a href="/search/Example%20Query/newest/advanced">this search</a>)
            already_subscribed_notice(@track_thing).should == expected
        end

    end

    describe 'when displaying notices for a user track' do

        before do
            @track_thing = FactoryGirl.build(:user_track)
        end

        it 'should create an already subscribed_notice' do
            expected = %Q(You are already subscribed to '#{user_link(@track_thing.tracked_user)}', a person)
            already_subscribed_notice(@track_thing).should == expected
        end

    end

    describe 'when displaying notices for a public body track' do

        before do
            @track_thing = FactoryGirl.build(:public_body_track)
        end

        it 'should create an already subscribed_notice' do
            expected = %Q(You are already subscribed to '#{public_body_link(@track_thing.public_body)}', a public authority)
            already_subscribed_notice(@track_thing).should == expected
        end

    end

    describe 'when displaying notices for a successful request track' do

        before do
            @track_thing = FactoryGirl.build(:successful_request_track)
        end

        it 'should create an already subscribed_notice' do
            expected = %Q(You are already subscribed to any <a href="/list/successful">successful requests</a>)
            already_subscribed_notice(@track_thing).should == expected
        end

    end

    describe 'when displaying notices for a new request track' do

        before do
            @track_thing = FactoryGirl.build(:new_request_track)
        end

        it 'should create an already subscribed_notice' do
            expected = %Q(You are already subscribed to any <a href="/list">new requests</a>)
            already_subscribed_notice(@track_thing).should == expected
        end

    end

    describe 'when displaying notices for a request update track' do

        before do
            @track_thing = FactoryGirl.build(:request_update_track)
        end

        it 'should create an already subscribed_notice' do
            expected = %Q(You are already subscribed to '#{request_link(@track_thing.info_request)}', a request)
            already_subscribed_notice(@track_thing).should == expected
        end

    end

end
