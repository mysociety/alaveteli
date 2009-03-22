require File.dirname(__FILE__) + '/../spec_helper'

describe PublicBody, " when saving" do
    before do
        @public_body = PublicBody.new 
    end

    it "should not be valid without setting some parameters" do
        @public_body.should_not be_valid
    end

    it "should not be valid with misformatted request email" do
        @public_body.name = "Testing Public Body"
        @public_body.short_name = "TPB"
        @public_body.request_email = "requestBOOlocalhost"
        @public_body.last_edit_editor = "*test*"
        @public_body.last_edit_comment = "This is a test"
        @public_body.should_not be_valid
        @public_body.should have(1).errors_on(:request_email)
    end

    it "should save" do
        @public_body.name = "Testing Public Body"
        @public_body.short_name = "TPB"
        @public_body.request_email = "request@localhost"
        @public_body.last_edit_editor = "*test*"
        @public_body.last_edit_comment = "This is a test"
        @public_body.save!
    end
end

describe PublicBody, "when searching" do
    fixtures :public_bodies

    it "should find by existing url name" do
        body = PublicBody.find_by_urlname('dfh')
        body.id.should == 3
    end

    it "should find by historic url name" do
        body = PublicBody.find_by_urlname('hdink')
        body.id.should == 3
        body.class.to_s.should == 'PublicBody'
    end

    it "should cope with not finding any" do
        body = PublicBody.find_by_urlname('idontexist')
        body.should be_nil
    end

end

describe PublicBody, " when indexing with Xapian" do
    fixtures :public_bodies

    before(:all) do
        rebuild_xapian_index
    end

    it "should search index the main name field" do
        xapian_object = InfoRequest.full_search([PublicBody], "humpadinking", 'created_at', true, nil, 100, 1)
        xapian_object.results.size.should == 1
        xapian_object.results[0][:model].should == public_bodies(:humpadink_public_body)
    end

    it "should search index the notes field" do
        xapian_object = InfoRequest.full_search([PublicBody], "albatross", 'created_at', true, nil, 100, 1)
        xapian_object.results.size.should == 1
        xapian_object.results[0][:model].should == public_bodies(:humpadink_public_body)
    end

end

