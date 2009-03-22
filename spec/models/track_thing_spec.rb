require File.dirname(__FILE__) + '/../spec_helper'

describe TrackThing, "when tracking changes" do
    fixtures :track_things, :users

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
        found_track = TrackThing.find_by_existing_track(users(:silly_name_user), track_thing)
        found_track.should == @track_thing
    end

end

