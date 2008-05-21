require File.dirname(__FILE__) + '/../spec_helper'

describe TrackThing, "when tracking changes" do
    fixtures :track_things, :users

    it "will find existing tracks which are the same" do
        track_thing = TrackThing.create_track_for_search_query('fancy dog')
        found_track = TrackThing.find_by_existing_track(users(:silly_name_user), track_thing)
        found_track.should == track_things(:track_fancy_dog_search)
    end

end
