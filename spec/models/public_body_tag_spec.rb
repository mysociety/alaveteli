require File.dirname(__FILE__) + '/../spec_helper'

describe PublicBodyTag, " when fiddling with public body tags " do
    fixtures :public_bodies

    it "should be able to make a new tag and save it" do
        @tag = PublicBodyTag.new 
        @tag.public_body = public_bodies(:geraldine_public_body)
        @tag.name = "moo"
        @tag.save
    end

end

