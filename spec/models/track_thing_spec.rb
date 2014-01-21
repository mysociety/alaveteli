# == Schema Information
#
# Table name: track_things
#
#  id               :integer          not null, primary key
#  tracking_user_id :integer          not null
#  track_query      :string(255)      not null
#  info_request_id  :integer
#  tracked_user_id  :integer
#  public_body_id   :integer
#  track_medium     :string(255)      not null
#  track_type       :string(255)      default("internal_error"), not null
#  created_at       :datetime
#  updated_at       :datetime
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe TrackThing, "when tracking changes" do

    before do
        @track_thing = track_things(:track_fancy_dog_search)
    end

    it "requires a type" do
        @track_thing.track_type = nil
        @track_thing.should have(2).errors_on(:track_type)
    end

    it "requires a valid type" do
        @track_thing.track_type = 'gibberish'
        @track_thing.should have(1).errors_on(:track_type)
    end

    it "requires a valid medium" do
        @track_thing.track_medium = 'pigeon'
        @track_thing.should have(1).errors_on(:track_medium)
    end

    it "will find existing tracks which are the same" do
        track_thing = TrackThing.create_track_for_search_query('fancy dog')
        found_track = TrackThing.find_existing(users(:silly_name_user), track_thing)
        found_track.should == @track_thing
    end

    it "can display the description of a deleted track_thing" do
        track_thing = TrackThing.create_track_for_search_query('fancy dog')
        description = track_thing.track_query_description
        track_thing.destroy
        track_thing.track_query_description.should == description
    end

    it "will make some sane descriptions of search-based tracks" do
        tests = { 'bob variety:user' => "users matching text 'bob'",
                  'bob (variety:sent OR variety:followup_sent OR variety:response OR variety:comment) (latest_status:successful OR latest_status:partially_successful OR latest_status:rejected OR latest_status:not_held)' => "comments or requests which are successful or unsuccessful matching text 'bob'",
                  '(latest_status:waiting_response OR latest_status:waiting_clarification OR waiting_classification:true)' => 'requests which are awaiting a response',
                  ' (variety:sent OR variety:followup_sent OR variety:response OR variety:comment)' => 'all requests or comments' }
        tests.each do |query, description|
            track_thing = TrackThing.create_track_for_search_query(query)
            track_thing.track_query_description.should == description
        end
    end

    it "will create an authority-based track when called using a 'bodies' postfix" do
        track_thing = TrackThing.create_track_for_search_query('fancy dog', 'bodies')
        track_thing.track_query.should =~ /variety:authority/
    end

end

