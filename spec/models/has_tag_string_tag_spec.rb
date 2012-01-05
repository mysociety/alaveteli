require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe HasTagString::HasTagStringTag, " when fiddling with tag strings " do
    fixtures :public_bodies, :public_body_translations, :public_body_versions, :info_requests, :raw_emails, :incoming_messages, :outgoing_messages, :comments, :info_request_events, :track_things

    it "should be able to make a new tag and save it" do
        @tag = HasTagString::HasTagStringTag.new 
        @tag.model = 'PublicBody'
        @tag.model_id = public_bodies(:geraldine_public_body).id
        @tag.name = "moo"
        @tag.save
    end

end

