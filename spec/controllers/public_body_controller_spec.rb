# coding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'nokogiri'

describe PublicBodyController, "when showing a body" do
    render_views

    before(:each) do
        load_raw_emails_data
        get_fixtures_xapian_index
    end

    it "should be successful" do
        get :show, :url_name => "dfh", :view => 'all'
        response.should be_success
    end

    it "should render with 'show' template" do
        get :show, :url_name => "dfh", :view => 'all'
        response.should render_template('show')
    end

    it "should assign the body" do
        get :show, :url_name => "dfh", :view => 'all'
        assigns[:public_body].should == public_bodies(:humpadink_public_body)
    end

    it "should assign the requests (1)" do
        get :show, :url_name => "tgq", :view => 'all'
        assigns[:xapian_requests].results.map{|x|x[:model].info_request}.should =~ InfoRequest.all(
            :conditions => ["public_body_id = ?", public_bodies(:geraldine_public_body).id])
    end

    it "should assign the requests (2)" do
        get :show, :url_name => "tgq", :view => 'successful'
        assigns[:xapian_requests].results.map{|x|x[:model].info_request}.should =~ InfoRequest.all(
            :conditions => ["described_state = ? and public_body_id = ?",
                "successful", public_bodies(:geraldine_public_body).id])
    end

    it "should assign the requests (3)" do
        get :show, :url_name => "dfh", :view => 'all'
        assigns[:xapian_requests].results.map{|x|x[:model].info_request}.should =~ InfoRequest.all(
            :conditions => ["public_body_id = ?", public_bodies(:humpadink_public_body).id])
    end

    it "should display the body using same locale as that used in url_name" do
        get :show, {:url_name => "edfh", :view => 'all', :locale => "es"}
        response.should contain("Baguette")
    end

    it 'should show public body names in the selected locale language if present for a locale with underscores' do
        AlaveteliLocalization.set_locales('he_IL en', 'en')
        get :show, {:url_name => 'dfh', :view => 'all', :locale => 'he_IL'}
        response.should contain('Hebrew Humpadinking')
    end

    it "should redirect use to the relevant locale even when url_name is for a different locale" do
        get :show, {:url_name => "edfh", :view => 'all'}
        response.should redirect_to "http://test.host/body/dfh"
    end

    it "should redirect to newest name if you use historic name of public body in URL" do
        get :show, :url_name => "hdink", :view => 'all'
        response.should redirect_to(:controller => 'public_body', :action => 'show', :url_name => "dfh")
    end

    it "should redirect to lower case name if you use mixed case name in URL" do
        get :show, :url_name => "dFh", :view => 'all'
        response.should redirect_to(:controller => 'public_body', :action => 'show', :url_name => "dfh")
    end
end

describe PublicBodyController, "when listing bodies" do
    render_views

    it "should be successful" do
        get :list
        response.should be_success
    end

    def make_single_language_example(locale)
        result = nil
        I18n.with_locale(locale) do
            case locale
            when :en
                result = PublicBody.new(:name => 'English only',
                                        :short_name => 'EO')
            when :es
                result = PublicBody.new(:name => 'Español Solamente',
                                        :short_name => 'ES')
            else
                raise StandardError.new "Unknown locale #{locale}"
            end
            result.request_email = "#{locale}@example.org"
            result.last_edit_editor = 'test'
            result.last_edit_comment = ''
            result.save
        end
        result
    end

    it "with no fallback, should only return bodies from the current locale" do
        @english_only = make_single_language_example :en
        @spanish_only = make_single_language_example :es
        get :list, {:locale => 'es'}
        assigns[:public_bodies].include?(@english_only).should == false
        assigns[:public_bodies].include?(@spanish_only).should == true
    end

    it "if fallback is requested, should list all bodies from default locale, even when there are no translations for selected locale" do
        AlaveteliConfiguration.stub!(:public_body_list_fallback_to_default_locale).and_return(true)
        @english_only = make_single_language_example :en
        get :list, {:locale => 'es'}
        assigns[:public_bodies].include?(@english_only).should == true
    end

    it 'if fallback is requested, should still list public bodies only with translations in the current locale' do
        AlaveteliConfiguration.stub!(:public_body_list_fallback_to_default_locale).and_return(true)
        @spanish_only = make_single_language_example :es
        get :list, {:locale => 'es'}
        assigns[:public_bodies].include?(@spanish_only).should == true
    end

    it "if fallback is requested, make sure that there are no duplicates listed" do
        AlaveteliConfiguration.stub!(:public_body_list_fallback_to_default_locale).and_return(true)
        get :list, {:locale => 'es'}
        pb_ids = assigns[:public_bodies].map { |pb| pb.id }
        unique_pb_ids = pb_ids.uniq
        pb_ids.sort.should === unique_pb_ids.sort
    end

    it 'should show public body names in the selected locale language if present' do
        get :list, {:locale => 'es'}
        response.should contain('El Department for Humpadinking')
    end

    it 'should not show the internal admin authority' do
        PublicBody.internal_admin_body
        get :list, {:locale => 'en'}
        response.should_not contain('Internal admin authority')
    end

    it 'should order on the translated name, even with the fallback' do
      # The names of each public body is in:
      #    <span class="head"><a>Public Body Name</a></span>
      # ... eo extract all of those, and check that they are ordered:
      AlaveteliConfiguration.stub!(:public_body_list_fallback_to_default_locale).and_return(true)
      get :list, {:locale => 'es'}
      parsed = Nokogiri::HTML(response.body)
      public_body_names = parsed.xpath '//span[@class="head"]/a/text()'
      public_body_names = public_body_names.map { |pb| pb.to_s }
      public_body_names.should == public_body_names.sort
    end

    it 'should show public body names in the selected locale language if present for a locale with underscores' do
        AlaveteliLocalization.set_locales('he_IL en', 'en')
        get :list, {:locale => 'he_IL'}
        response.should contain('Hebrew Humpadinking')
    end


    it "should list bodies in alphabetical order" do
        # Note that they are alphabetised by localised name
        get :list

        response.should render_template('list')

        assigns[:public_bodies].should == [ public_bodies(:other_public_body),
            public_bodies(:humpadink_public_body),
            public_bodies(:forlorn_public_body),
            public_bodies(:geraldine_public_body),
            public_bodies(:sensible_walks_public_body),
            public_bodies(:silly_walks_public_body) ]
        assigns[:tag].should == "all"
        assigns[:description].should == ""
    end

    it "should support simple searching of bodies by title" do
        get :list, :public_body_query => 'quango'
        assigns[:public_bodies].should == [ public_bodies(:geraldine_public_body) ]
    end

    it "should support simple searching of bodies by notes" do
        get :list, :public_body_query => 'Albatross'
        assigns[:public_bodies].should == [ public_bodies(:humpadink_public_body) ]
    end

    it "should list bodies in alphabetical order with different locale" do
        I18n.default_locale = :es
        get :list
        response.should render_template('list')
        assigns[:public_bodies].should == [ public_bodies(:geraldine_public_body), public_bodies(:humpadink_public_body) ]
        assigns[:tag].should == "all"
        assigns[:description].should == ""
        I18n.default_locale = :en
    end

    it "should list a tagged thing on the appropriate list page, and others on the other page, and all still on the all page" do
        load_test_categories

        public_bodies(:humpadink_public_body).tag_string = "foo local_council"

        get :list, :tag => "local_council"
        response.should render_template('list')
        assigns[:public_bodies].should == [ public_bodies(:humpadink_public_body) ]
        assigns[:tag].should == "local_council"
        assigns[:description].should == "in the category ‘Local councils’"

        get :list, :tag => "other"
        response.should render_template('list')
        assigns[:public_bodies].should == [ public_bodies(:other_public_body),
            public_bodies(:forlorn_public_body),
            public_bodies(:geraldine_public_body),
            public_bodies(:sensible_walks_public_body),
            public_bodies(:silly_walks_public_body) ]

        get :list
        response.should render_template('list')
        assigns[:public_bodies].should == [ public_bodies(:other_public_body),
            public_bodies(:humpadink_public_body),
            public_bodies(:forlorn_public_body),
            public_bodies(:geraldine_public_body),
            public_bodies(:sensible_walks_public_body),
            public_bodies(:silly_walks_public_body) ]
    end

    it "should list a machine tagged thing, should get it in both ways" do
        public_bodies(:humpadink_public_body).tag_string = "eats_cheese:stilton"

        get :list, :tag => "eats_cheese"
        response.should render_template('list')
        assigns[:public_bodies].should == [ public_bodies(:humpadink_public_body) ]
        assigns[:tag].should == "eats_cheese"

        get :list, :tag => "eats_cheese:jarlsberg"
        response.should render_template('list')
        assigns[:public_bodies].should == [ ]
        assigns[:tag].should == "eats_cheese:jarlsberg"

        get :list, :tag => "eats_cheese:stilton"
        response.should render_template('list')
        assigns[:public_bodies].should == [ public_bodies(:humpadink_public_body) ]
        assigns[:tag].should == "eats_cheese:stilton"
    end

    it 'should return a "406 Not Acceptable" code if asked for a json version of a list' do
        get :list, :format => 'json'
        response.code.should == '406'
    end

end

describe PublicBodyController, "when showing JSON version for API" do

    it "should be successful" do
        get :show, :url_name => "dfh", :format => "json", :view => 'all'

        pb = JSON.parse(response.body)
        pb.class.to_s.should == 'Hash'

        pb['url_name'].should == 'dfh'
        pb['notes'].should == 'An albatross told me!!!'
    end

end

describe PublicBodyController, "when showing public body statistics" do

  it "should render the right template with the right data" do
    config = MySociety::Config.load_default()
    config['MINIMUM_REQUESTS_FOR_STATISTICS'] = 1
    config['PUBLIC_BODY_STATISTICS_PAGE'] = true
    get :statistics
    response.should render_template('public_body/statistics')
    # There are 5 different graphs we're creating at the moment.
    assigns[:graph_list].length.should == 5
    # The first is the only one with raw values, the rest are
    # percentages with error bars:
    assigns[:graph_list].each_with_index do |graph, index|
      if index == 0
        graph['errorbars'].should be_false
        graph['x_values'].length.should == 4
        graph['x_values'].should == [0, 1, 2, 3]
        graph['y_values'].should == [1, 2, 2, 4]
      else
        graph['errorbars'].should be_true
        # Just check the first one:
        if index == 1
          graph['x_values'].should == [0, 1, 2, 3]
          graph['y_values'].should == [0, 50, 100, 100]
        end
        # Check that at least every confidence interval value is
        # a Float (rather than NilClass, say):
        graph['cis_below'].each { |v| v.should be_instance_of(Float) }
        graph['cis_above'].each { |v| v.should be_instance_of(Float) }
      end
    end
  end

end

describe PublicBodyController, "when doing type ahead searches" do

    render_views

    before(:each) do
        load_raw_emails_data
        get_fixtures_xapian_index
    end

    it "should return nothing for the empty query string" do
        get :search_typeahead, :query => ""
        response.should render_template('public_body/_search_ahead')
        assigns[:xapian_requests].should be_nil
    end

    it "should return a body matching the given keyword, but not users with a matching description" do
        get :search_typeahead, :query => "Geraldine"
        response.should render_template('public_body/_search_ahead')
        response.body.should include('search_ahead')
        assigns[:xapian_requests].results.size.should == 1
        assigns[:xapian_requests].results[0][:model].name.should == public_bodies(:geraldine_public_body).name
    end

    it "should return all requests matching any of the given keywords" do
        get :search_typeahead, :query => "Geraldine Humpadinking"
        response.should render_template('public_body/_search_ahead')
        assigns[:xapian_requests].results.map{|x|x[:model]}.should =~ [
            public_bodies(:humpadink_public_body),
            public_bodies(:geraldine_public_body),
        ]
    end

    it "should return requests matching the given keywords in any of their locales" do
        get :search_typeahead, :query => "baguette" # part of the spanish notes
        response.should render_template('public_body/_search_ahead')
        assigns[:xapian_requests].results.map{|x|x[:model]}.should =~ [public_bodies(:humpadink_public_body)]
    end

    it "should not return  matches for short words" do
        get :search_typeahead, :query => "b"
        response.should render_template('public_body/_search_ahead')
        assigns[:xapian_requests].should be_nil
    end
end
