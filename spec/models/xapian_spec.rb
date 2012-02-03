require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe User, " when indexing users with Xapian" do

    before(:each) do
        load_raw_emails_data
        rebuild_xapian_index
    end
    
    it "should search by name" do
        # def InfoRequest.full_search(models, query, order, ascending, collapse, per_page, page)
        xapian_object = InfoRequest.full_search([User], "Silly", 'created_at', true, nil, 100, 1)
        xapian_object.results.size.should == 1
        xapian_object.results[0][:model].should == users(:silly_name_user)
    end

    it "should search by 'about me' text" do
        user = users(:bob_smith_user)

        # def InfoRequest.full_search(models, query, order, ascending, collapse, per_page, page)
        xapian_object = InfoRequest.full_search([User], "stuff", 'created_at', true, nil, 100, 1)
        xapian_object.results.size.should == 1
        xapian_object.results[0][:model].should == user
        
        user.about_me = "I am really an aardvark, true story."
        user.save!
        update_xapian_index

        xapian_object = InfoRequest.full_search([User], "stuff", 'created_at', true, nil, 100, 1)
        xapian_object.results.size.should == 0

        xapian_object = InfoRequest.full_search([User], "aardvark", 'created_at', true, nil, 100, 1)
        xapian_object.results.size.should == 1
        xapian_object.results[0][:model].should == user
    end
end

describe PublicBody, " when indexing public bodies with Xapian" do
    before(:each) do
        load_raw_emails_data
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

    it "should delete public bodies from the index when they are destroyed" do
        xapian_object = InfoRequest.full_search([PublicBody], "albatross", 'created_at', true, nil, 100, 1)
        xapian_object.results.size.should == 1
        xapian_object.results[0][:model].should == public_bodies(:humpadink_public_body)

        public_bodies(:forlorn_public_body).destroy

        update_xapian_index
        xapian_object = InfoRequest.full_search([PublicBody], "lonely", 'created_at', true, nil, 100, 1)
        xapian_object.results.should == []
    end

end

describe PublicBody, " when indexing requests by body they are to" do

    before(:each) do
        load_raw_emails_data
        rebuild_xapian_index
    end

    it "should find requests to the body" do
        xapian_object = InfoRequest.full_search([InfoRequestEvent], "requested_from:tgq", 'created_at', true, nil, 100, 1)
        xapian_object.results.size.should == 4
    end

    it "should update index correctly when URL name of body changes" do
        # initial search
        xapian_object = InfoRequest.full_search([InfoRequestEvent], "requested_from:tgq", 'created_at', true, nil, 100, 1)
        xapian_object.results.size.should == 4
        models_found_before = xapian_object.results.map { |x| x[:model] }

        # change the URL name of the body
        body = public_bodies(:geraldine_public_body)
        body.short_name = 'GQ'
        body.save!
        body.url_name.should == 'gq'
        update_xapian_index

        # check we get results expected
        xapian_object = InfoRequest.full_search([InfoRequestEvent], "requested_from:tgq", 'created_at', true, nil, 100, 1)
        xapian_object.results.size.should == 0
        xapian_object = InfoRequest.full_search([InfoRequestEvent], "requested_from:gq", 'created_at', true, nil, 100, 1)
        xapian_object.results.size.should == 4
        models_found_after = xapian_object.results.map { |x| x[:model] }

        models_found_before.should == models_found_after
    end

    # if you index via the Xapian TermGenerator, it ignores terms of this length,
    # this checks we're using Document:::add_term() instead
    it "should work with URL names that are longer than 64 characters" do
        # change the URL name of the body
        body = public_bodies(:geraldine_public_body)
        body.short_name = 'The Uncensored, Complete Name of the Quasi-Autonomous Public Body Also Known As Geraldine'
        body.save!
        body.url_name.size.should > 70
        update_xapian_index

        # check we get results expected
        xapian_object = InfoRequest.full_search([InfoRequestEvent], "requested_from:tgq", 'created_at', true, nil, 100, 1)
        xapian_object.results.size.should == 0
        xapian_object = InfoRequest.full_search([InfoRequestEvent], "requested_from:gq", 'created_at', true, nil, 100, 1)
        xapian_object.results.size.should == 0
        xapian_object = InfoRequest.full_search([InfoRequestEvent], "requested_from:" + body.url_name, 'created_at', true, nil, 100, 1)
        xapian_object.results.size.should == 4
        models_found_after = xapian_object.results.map { |x| x[:model] }
    end
end

describe User, " when indexing requests by user they are from" do
    before(:each) do
        load_raw_emails_data
        rebuild_xapian_index
    end

    it "should find requests from the user" do
        xapian_object = InfoRequest.full_search([InfoRequestEvent], "requested_by:bob_smith", 'created_at', true, nil, 100, 1)
        xapian_object.results.map{|x|x[:model]}.should =~ InfoRequestEvent.all(:conditions => "info_request_id in (select id from info_requests where user_id = #{users(:bob_smith_user).id})")
    end

    it "should find just the sent message events from a particular user" do
          # def InfoRequest.full_search(models, query, order, ascending, collapse, per_page, page)
        xapian_object = InfoRequest.full_search([InfoRequestEvent], "requested_by:bob_smith variety:sent", 'created_at', true, nil, 100, 1)
        xapian_object.results.map{|x|x[:model]}.should =~ InfoRequestEvent.all(:conditions => "info_request_id in (select id from info_requests where user_id = #{users(:bob_smith_user).id}) and event_type = 'sent'")
        xapian_object.results[2][:model].should == info_request_events(:useless_outgoing_message_event)
        xapian_object.results[1][:model].should == info_request_events(:silly_outgoing_message_event)
    end

    it "should not find it when one of the request's users is changed" do
        silly_user = users(:silly_name_user)
        naughty_chicken_request = info_requests(:naughty_chicken_request)
        naughty_chicken_request.user = silly_user
        naughty_chicken_request.save!

        update_xapian_index

          # def InfoRequest.full_search(models, query, order, ascending, collapse, per_page, page)
        xapian_object = InfoRequest.full_search([InfoRequestEvent], "requested_by:bob_smith", 'created_at', true, 'request_collapse', 100, 1)
        xapian_object.results.map{|x|x[:model].info_request}.should =~ InfoRequest.all(:conditions => "user_id = #{users(:bob_smith_user).id}")
    end

    it "should not get confused searching for requests when one user has a name which has same stem as another" do
        bob_smith_user = users(:bob_smith_user)
        bob_smith_user.name = "John King"
        bob_smith_user.url_name.should == 'john_king'
        bob_smith_user.save!

        silly_user = users(:silly_name_user)
        silly_user.name = "John K"
        silly_user.url_name.should == 'john_k'
        silly_user.save!

        naughty_chicken_request = info_requests(:naughty_chicken_request)
        naughty_chicken_request.user = silly_user
        naughty_chicken_request.save!

        update_xapian_index

          # def InfoRequest.full_search(models, query, order, ascending, collapse, per_page, page)
        xapian_object = InfoRequest.full_search([InfoRequestEvent], "requested_by:john_k", 'created_at', true, 'request_collapse', 100, 1)
        xapian_object.results.size.should == 1
        xapian_object.results[0][:model].should == info_request_events(:silly_outgoing_message_event)
    end


    it "should update index correctly when URL name of user changes" do
        # initial search
        xapian_object = InfoRequest.full_search([InfoRequestEvent], "requested_by:bob_smith", 'created_at', true, nil, 100, 1)
        xapian_object.results.map{|x|x[:model]}.should =~ InfoRequestEvent.all(:conditions => "info_request_id in (select id from info_requests where user_id = #{users(:bob_smith_user).id})")
        models_found_before = xapian_object.results.map { |x| x[:model] }

        # change the URL name of the body
        u= users(:bob_smith_user)
        u.name = 'Robert Smith'
        u.save!
        u.url_name.should == 'robert_smith'
        update_xapian_index

        # check we get results expected
        xapian_object = InfoRequest.full_search([InfoRequestEvent], "requested_by:bob_smith", 'created_at', true, nil, 100, 1)
        xapian_object.results.size.should == 0
        xapian_object = InfoRequest.full_search([InfoRequestEvent], "requested_by:robert_smith", 'created_at', true, nil, 100, 1)
        models_found_after = xapian_object.results.map { |x| x[:model] }
        models_found_before.should == models_found_after
    end
end

describe User, " when indexing comments by user they are by" do
    before(:each) do
        load_raw_emails_data
        rebuild_xapian_index
    end

    it "should find requests from the user" do
        xapian_object = InfoRequest.full_search([InfoRequestEvent], "commented_by:silly_emnameem", 'created_at', true, nil, 100, 1)
        xapian_object.results.size.should == 1
    end

    it "should update index correctly when URL name of user changes" do
        # initial search
        xapian_object = InfoRequest.full_search([InfoRequestEvent], "commented_by:silly_emnameem", 'created_at', true, nil, 100, 1)
        xapian_object.results.size.should == 1
        models_found_before = xapian_object.results.map { |x| x[:model] }

        # change the URL name of the body
        u = users(:silly_name_user)
        u.name = 'Silly Name'
        u.save!
        u.url_name.should == 'silly_name'
        update_xapian_index

        # check we get results expected
        xapian_object = InfoRequest.full_search([InfoRequestEvent], "commented_by:silly_emnameem", 'created_at', true, nil, 100, 1)
        xapian_object.results.size.should == 0
        xapian_object = InfoRequest.full_search([InfoRequestEvent], "commented_by:silly_name", 'created_at', true, nil, 100, 1)
        xapian_object.results.size.should == 1
        models_found_after = xapian_object.results.map { |x| x[:model] }

        models_found_before.should == models_found_after
    end
end

describe InfoRequest, " when indexing requests by their title" do
    before(:each) do
        load_raw_emails_data
        rebuild_xapian_index
    end

    it "should find events for the request" do
        xapian_object = InfoRequest.full_search([InfoRequestEvent], "request:how_much_public_money_is_wasted_o", 'created_at', true, nil, 100, 1)
        xapian_object.results.size.should == 1
        xapian_object.results[0][:model] == info_request_events(:silly_outgoing_message_event)
    end

    it "should update index correctly when URL title of request changes" do
        # change the URL name of the body
        ir = info_requests(:naughty_chicken_request)
        ir.title = 'Really naughty'
        ir.save!
        ir.url_title.should == 'really_naughty'
        update_xapian_index

        # check we get results expected
        xapian_object = InfoRequest.full_search([InfoRequestEvent], "request:how_much_public_money_is_wasted_o", 'created_at', true, nil, 100, 1)
        xapian_object.results.size.should == 0
        xapian_object = InfoRequest.full_search([InfoRequestEvent], "request:really_naughty", 'created_at', true, nil, 100, 1)
        xapian_object.results.size.should == 1
        xapian_object.results[0][:model] == info_request_events(:silly_outgoing_message_event)
    end
end

describe InfoRequest, " when indexing requests by tag" do
    before(:each) do
        load_raw_emails_data
        rebuild_xapian_index
    end

    it "should find request by tag, even when changes" do
        ir = info_requests(:naughty_chicken_request)
        ir.tag_string = 'bunnyrabbit'
        ir.save!
        update_xapian_index

        xapian_object = InfoRequest.full_search([InfoRequestEvent], "tag:bunnyrabbit", 'created_at', true, nil, 100, 1)
        xapian_object.results.size.should == 1
        xapian_object.results[0][:model] == info_request_events(:silly_outgoing_message_event)

        xapian_object = InfoRequest.full_search([InfoRequestEvent], "tag:orangeaardvark", 'created_at', true, nil, 100, 1)
        xapian_object.results.size.should == 0
    end
end

describe PublicBody, " when indexing authorities by tag" do
    before(:each) do
        load_raw_emails_data
        rebuild_xapian_index
    end

    it "should find request by tag, even when changes" do
        body = public_bodies(:geraldine_public_body)
        body.tag_string = 'mice:3'
        body.save!
        update_xapian_index

        xapian_object = InfoRequest.full_search([PublicBody], "tag:mice", 'created_at', true, nil, 100, 1)
        xapian_object.results.size.should == 1
        xapian_object.results[0][:model] == public_bodies(:geraldine_public_body)
        xapian_object = InfoRequest.full_search([PublicBody], "tag:mice:3", 'created_at', true, nil, 100, 1)
        xapian_object.results.size.should == 1
        xapian_object.results[0][:model] == public_bodies(:geraldine_public_body)

        xapian_object = InfoRequest.full_search([PublicBody], "tag:orangeaardvark", 'created_at', true, nil, 100, 1)
        xapian_object.results.size.should == 0
    end
end

describe PublicBody, " when only indexing selected things on a rebuild" do
    before(:each) do
        load_raw_emails_data
        rebuild_xapian_index
    end

    it "should only index what we ask it to" do
        body = public_bodies(:geraldine_public_body)
        body.tag_string = 'mice:3'
        body.name = 'frobzn'
        body.save!
        # only reindex 'variety' term
        dropfirst = true
        terms = "V"
        values = false
        texts = false
        rebuild_xapian_index(terms, values, texts, dropfirst)
        xapian_object = InfoRequest.full_search([PublicBody], "tag:mice", 'created_at', true, nil, 100, 1)
        xapian_object.results.size.should == 0
        xapian_object = InfoRequest.full_search([PublicBody], "frobzn", 'created_at', true, nil, 100, 1)
        xapian_object.results.size.should == 0
        xapian_object = InfoRequest.full_search([PublicBody], "variety:authority", 'created_at', true, nil, 100, 1)
        xapian_object.results.map{|x|x[:model]}.should =~ PublicBody.all
        # only reindex 'tag' and text
        dropfirst = true
        terms = "U"
        values = false
        texts = true
        rebuild_xapian_index(terms, values, texts, dropfirst)
        xapian_object = InfoRequest.full_search([PublicBody], "tag:mice", 'created_at', true, nil, 100, 1)
        xapian_object.results.size.should == 1
        xapian_object = InfoRequest.full_search([PublicBody], "frobzn", 'created_at', true, nil, 100, 1)
        xapian_object.results.size.should == 1
        xapian_object = InfoRequest.full_search([PublicBody], "variety:authority", 'created_at', true, nil, 100, 1)
        xapian_object.results.size.should == 0
        # only reindex 'variety' term, but keeping the existing data in-place
        dropfirst = false
        terms = "V"
        texts = false
        rebuild_xapian_index(terms, values, texts, dropfirst)
        xapian_object = InfoRequest.full_search([PublicBody], "tag:mice", 'created_at', true, nil, 100, 1)
        xapian_object.results.size.should == 1
        xapian_object = InfoRequest.full_search([PublicBody], "frobzn", 'created_at', true, nil, 100, 1)
        xapian_object.results.size.should == 1
        xapian_object = InfoRequest.full_search([PublicBody], "variety:authority", 'created_at', true, nil, 100, 1)
        xapian_object.results.map{|x|x[:model]}.should =~ PublicBody.all
        # only reindex 'variety' term, blowing away existing data
        dropfirst = true
        rebuild_xapian_index(terms, values, texts, dropfirst)
        xapian_object = InfoRequest.full_search([PublicBody], "tag:mice", 'created_at', true, nil, 100, 1)
        xapian_object.results.size.should == 0
        xapian_object = InfoRequest.full_search([PublicBody], "frobzn", 'created_at', true, nil, 100, 1)
        xapian_object.results.size.should == 0
        xapian_object = InfoRequest.full_search([PublicBody], "variety:authority", 'created_at', true, nil, 100, 1)
        xapian_object.results.map{|x|x[:model]}.should =~ PublicBody.all
    end
end

