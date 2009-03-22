require File.dirname(__FILE__) + '/../spec_helper'

describe User, " when indexing with Xapian" do
    fixtures :users

    before(:all) do
        rebuild_xapian_index
    end

    it "should search by name" do
          # def InfoRequest.full_search(models, query, order, ascending, collapse, per_page, page)
        xapian_object = InfoRequest.full_search([User], "Silly", 'created_at', true, nil, 100, 1)
        xapian_object.results.size.should == 1
        xapian_object.results[0][:model].should == users(:silly_name_user)
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


