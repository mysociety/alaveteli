# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe HasTagString::HasTagStringTag, " when fiddling with tag strings" do

  it "should be able to make a new tag and save it" do
    @tag = HasTagString::HasTagStringTag.new
    @tag.model = 'PublicBody'
    @tag.model_id = public_bodies(:geraldine_public_body).id
    @tag.name = "moo"
    @tag.save
  end

end
