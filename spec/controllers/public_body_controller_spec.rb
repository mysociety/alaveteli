# -*- encoding : utf-8 -*-
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
    expect(response).to be_success
  end

  it "should render with 'show' template" do
    get :show, :url_name => "dfh", :view => 'all'
    expect(response).to render_template('show')
  end

  it "should assign the body" do
    get :show, :url_name => "dfh", :view => 'all'
    expect(assigns[:public_body]).to eq(public_bodies(:humpadink_public_body))
  end

  it "should assign the requests (1)" do
    get :show, :url_name => "tgq", :view => 'all'
    expect(assigns[:xapian_requests].results.map{|x|x[:model].info_request}).to match_array(InfoRequest.all(
    :conditions => ["public_body_id = ?", public_bodies(:geraldine_public_body).id]))
  end

  it "should assign the requests (2)" do
    get :show, :url_name => "tgq", :view => 'successful'
    expect(assigns[:xapian_requests].results.map{|x|x[:model].info_request}).to match_array(InfoRequest.all(
      :conditions => ["described_state = ? and public_body_id = ?",
                      "successful", public_bodies(:geraldine_public_body).id]))
  end

  it "should assign the requests (3)" do
    get :show, :url_name => "dfh", :view => 'all'
    expect(assigns[:xapian_requests].results.map{|x|x[:model].info_request}).to match_array(InfoRequest.all(
    :conditions => ["public_body_id = ?", public_bodies(:humpadink_public_body).id]))
  end

  it "should display the body using same locale as that used in url_name" do
    get :show, {:url_name => "edfh", :view => 'all', :locale => "es"}
    expect(response.body).to have_content("Baguette")
  end

  it 'should show public body names in the selected locale language if present for a locale with underscores' do
    AlaveteliLocalization.set_locales('he_IL en', 'en')
    get :show, {:url_name => 'dfh', :view => 'all', :locale => 'he_IL'}
    expect(response.body).to have_content('Hebrew Humpadinking')
  end

  it "should redirect use to the relevant locale even when url_name is for a different locale" do
    get :show, {:url_name => "edfh", :view => 'all'}
    expect(response).to redirect_to "http://test.host/body/dfh"
  end

  it "should redirect to newest name if you use historic name of public body in URL" do
    get :show, :url_name => "hdink", :view => 'all'
    expect(response).to redirect_to(:controller => 'public_body', :action => 'show', :url_name => "dfh")
  end

  it "should redirect to lower case name if you use mixed case name in URL" do
    get :show, :url_name => "dFh", :view => 'all'
    expect(response).to redirect_to(:controller => 'public_body', :action => 'show', :url_name => "dfh")
  end

  it 'keeps the search_params flash' do
    # Make two get requests to simulate the flash getting swept after the
    # first response.
    search_params = { 'query' => 'Quango' }
    get :show, { :url_name => 'dfh', :view => 'all' },
      nil,
      { :search_params => search_params }
    get :show, :url_name => 'dfh', :view => 'all'
    expect(flash[:search_params]).to eq(search_params)
  end


  it 'should not show high page offsets as these are extremely slow to generate' do
    expect {
      get :show, { :url_name => 'dfh', :view => 'all', :page => 25 }
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

end

describe PublicBodyController, "when listing bodies" do
  render_views

  it "should be successful" do
    get :list
    expect(response).to be_success
  end

  def make_single_language_example(locale)
    result = nil
    with_default_locale(locale) do
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
    end
    result
  end

  it "with no fallback, should only return bodies from the current locale" do
    @english_only = make_single_language_example :en
    @spanish_only = make_single_language_example :es
    get :list, {:locale => 'es'}
    expect(assigns[:public_bodies].include?(@english_only)).to eq(false)
    expect(assigns[:public_bodies].include?(@spanish_only)).to eq(true)
  end

  it "if fallback is requested, should list all bodies from default locale, even when there are no translations for selected locale" do
    allow(AlaveteliConfiguration).to receive(:public_body_list_fallback_to_default_locale).and_return(true)
    @english_only = make_single_language_example :en
    get :list, {:locale => 'es'}
    expect(assigns[:public_bodies].include?(@english_only)).to eq(true)
  end

  it 'if fallback is requested, should still list public bodies only with translations in the current locale' do
    allow(AlaveteliConfiguration).to receive(:public_body_list_fallback_to_default_locale).and_return(true)
    @spanish_only = make_single_language_example :es
    get :list, {:locale => 'es'}
    expect(assigns[:public_bodies].include?(@spanish_only)).to eq(true)
  end

  it "if fallback is requested, make sure that there are no duplicates listed" do
    allow(AlaveteliConfiguration).to receive(:public_body_list_fallback_to_default_locale).and_return(true)
    get :list, {:locale => 'es'}
    pb_ids = assigns[:public_bodies].map { |pb| pb.id }
    unique_pb_ids = pb_ids.uniq
    expect(pb_ids.sort).to be === unique_pb_ids.sort
  end

  it 'should show public body names in the selected locale language if present' do
    get :list, {:locale => 'es'}
    expect(response.body).to have_content('El Department for Humpadinking')
  end

  it 'should not show the internal admin authority' do
    PublicBody.internal_admin_body
    get :list, {:locale => 'en'}
    expect(response.body).not_to have_content('Internal admin authority')
  end

  it 'should order on the translated name, even with the fallback' do
    # The names of each public body is in:
    #    <span class="head"><a>Public Body Name</a></span>
    # ... eo extract all of those, and check that they are ordered:
    allow(AlaveteliConfiguration).to receive(:public_body_list_fallback_to_default_locale).and_return(true)
    get :list, {:locale => 'es'}
    parsed = Nokogiri::HTML(response.body)
    public_body_names = parsed.xpath '//span[@class="head"]/a/text()'
    public_body_names = public_body_names.map { |pb| pb.to_s }
    expect(public_body_names).to eq(public_body_names.sort)
  end

  it 'should show public body names in the selected locale language if present for a locale with underscores' do
    AlaveteliLocalization.set_locales('he_IL en', 'en')
    get :list, {:locale => 'he_IL'}
    expect(response.body).to have_content('Hebrew Humpadinking')
  end


  it "should list bodies in alphabetical order" do
    # Note that they are alphabetised by localised name
    get :list

    expect(response).to render_template('list')

    expect(assigns[:public_bodies]).to eq([ public_bodies(:other_public_body),
                                        public_bodies(:humpadink_public_body),
                                        public_bodies(:forlorn_public_body),
                                        public_bodies(:geraldine_public_body),
                                        public_bodies(:sensible_walks_public_body),
                                        public_bodies(:silly_walks_public_body) ])
    expect(assigns[:tag]).to eq("all")
    expect(assigns[:description]).to eq("")
  end

  it 'list bodies in collate order according to the locale with the fallback set' do
    allow(AlaveteliConfiguration).to receive(:public_body_list_fallback_to_default_locale).
      and_return(true)

    allow(DatabaseCollation).to receive(:supports?).
      with(an_instance_of(String)).
        and_return(true)

    get :list, :locale => 'en_GB'
    expect(assigns[:sql].to_s).to include('COLLATE')
  end

  it 'list bodies in default order according to the locale with the fallback set' do
    allow(AlaveteliConfiguration).to receive(:public_body_list_fallback_to_default_locale).
      and_return(true)

    allow(DatabaseCollation).to receive(:supports?).
      with(an_instance_of(String)).
        and_return(false)

    get :list, :locale => 'unknown'

    expect(assigns[:sql].to_s).to_not include('COLLATE')
  end

  it 'list bodies in collate order according to the locale' do
    allow(AlaveteliConfiguration).to receive(:public_body_list_fallback_to_default_locale).
      and_return(false)

    allow(DatabaseCollation).to receive(:supports?).
      with(an_instance_of(String)).
        and_return(true)

    get :list, :locale => 'en_GB'

    expect(assigns[:public_bodies].to_sql).to include('COLLATE')
  end

  it 'list bodies in alphabetical order according to the locale' do
    allow(AlaveteliConfiguration).to receive(:public_body_list_fallback_to_default_locale).
      and_return(false)

    allow(DatabaseCollation).to receive(:supports?).
      with(an_instance_of(String)).
        and_return(false)

    get :list, :locale => 'unknown'

    expect(assigns[:public_bodies].to_sql).to_not include('COLLATE')
  end

  it "should support simple searching of bodies by title" do
    get :list, :public_body_query => 'quango'
    expect(assigns[:public_bodies]).to eq([ public_bodies(:geraldine_public_body) ])
  end

  it "should support simple searching of bodies by short_name" do
    get :list, :public_body_query => 'DfH'
    expect(assigns[:public_bodies]).to eq([ public_bodies(:humpadink_public_body) ])
  end

  it "should support simple searching of bodies by notes" do
    get :list, :public_body_query => 'Albatross'
    expect(assigns[:public_bodies]).to eq([ public_bodies(:humpadink_public_body) ])
  end

  it "should list bodies in alphabetical order with different locale" do
    with_default_locale(:es) do
      get :list
      expect(response).to render_template('list')
      expect(assigns[:public_bodies]).to eq([ public_bodies(:geraldine_public_body), public_bodies(:humpadink_public_body) ])
      expect(assigns[:tag]).to eq("all")
      expect(assigns[:description]).to eq("")
    end
  end

  it "should list a tagged thing on the appropriate list page, and others on the other page,
        and all still on the all page" do
    category = FactoryGirl.create(:public_body_category)
    heading = FactoryGirl.create(:public_body_heading)
    PublicBodyCategoryLink.create(:public_body_heading_id => heading.id,
                                  :public_body_category_id => category.id)
    public_bodies(:humpadink_public_body).tag_string = category.category_tag

    get :list, :tag => category.category_tag
    expect(response).to render_template('list')
    expect(assigns[:public_bodies]).to eq([ public_bodies(:humpadink_public_body) ])
    expect(assigns[:tag]).to eq(category.category_tag)
    expect(assigns[:description]).to eq("in the category ‘#{category.title}’")

    get :list, :tag => "other"
    expect(response).to render_template('list')
    expect(assigns[:public_bodies]).to eq([ public_bodies(:other_public_body),
                                        public_bodies(:forlorn_public_body),
                                        public_bodies(:geraldine_public_body),
                                        public_bodies(:sensible_walks_public_body),
                                        public_bodies(:silly_walks_public_body) ])

    get :list
    expect(response).to render_template('list')
    expect(assigns[:public_bodies]).to eq([ public_bodies(:other_public_body),
                                        public_bodies(:humpadink_public_body),
                                        public_bodies(:forlorn_public_body),
                                        public_bodies(:geraldine_public_body),
                                        public_bodies(:sensible_walks_public_body),
                                        public_bodies(:silly_walks_public_body) ])
  end

  it "should list a machine tagged thing, should get it in both ways" do
    public_bodies(:humpadink_public_body).tag_string = "eats_cheese:stilton"

    get :list, :tag => "eats_cheese"
    expect(response).to render_template('list')
    expect(assigns[:public_bodies]).to eq([ public_bodies(:humpadink_public_body) ])
    expect(assigns[:tag]).to eq("eats_cheese")

    get :list, :tag => "eats_cheese:jarlsberg"
    expect(response).to render_template('list')
    expect(assigns[:public_bodies]).to eq([ ])
    expect(assigns[:tag]).to eq("eats_cheese:jarlsberg")

    get :list, :tag => "eats_cheese:stilton"
    expect(response).to render_template('list')
    expect(assigns[:public_bodies]).to eq([ public_bodies(:humpadink_public_body) ])
    expect(assigns[:tag]).to eq("eats_cheese:stilton")
  end

  it 'should return a "406 Not Acceptable" code if asked for a json version of a list' do
    get :list, :format => 'json'
    expect(response.code).to eq('406')
  end

  it "should list authorities starting with a multibyte first letter" do
    get :list, {:tag => "å", :show_locale => 'cs'}
    expect(response).to render_template('list')
    expect(assigns[:public_bodies]).to eq([ public_bodies(:accented_public_body) ])
    expect(assigns[:tag]).to eq("Å")
  end

end

describe PublicBodyController, "when showing JSON version for API" do

  it "should be successful" do
    get :show, :url_name => "dfh", :format => "json", :view => 'all'

    pb = JSON.parse(response.body)
    expect(pb.class.to_s).to eq('Hash')

    expect(pb['url_name']).to eq('dfh')
    expect(pb['notes']).to eq('An albatross told me!!!')
  end

end

describe PublicBodyController, "when asked to export public bodies as CSV" do

  it "should return a valid CSV file with the right number of rows" do
    get :list_all_csv
    all_data = CSV.parse response.body
    expect(all_data.length).to eq(8)
    # Check that the header has the right number of columns:
    expect(all_data[0].length).to eq(11)
    # And an actual line of data:
    expect(all_data[1].length).to eq(11)
  end

  it "only includes visible bodies" do
    get :list_all_csv
    all_data = CSV.parse(response.body)
    expect(all_data.any?{ |row| row.include?('Internal admin authority') }).to be false
  end

  it "does not include site_administration bodies" do
    FactoryGirl.create(:public_body,
                       :name => 'Site Admin Body',
                       :tag_string => 'site_administration')

    get :list_all_csv

    all_data = CSV.parse(response.body)
    expect(all_data.any?{ |row| row.include?('Site Admin Body') }).to be false
  end

end

describe PublicBodyController, "when showing public body statistics" do

  it "should render the right template with the right data" do
    config = MySociety::Config.load_default
    config['MINIMUM_REQUESTS_FOR_STATISTICS'] = 1
    config['PUBLIC_BODY_STATISTICS_PAGE'] = true
    get :statistics
    expect(response).to render_template('public_body/statistics')
    # There are 5 different graphs we're creating at the moment.
    expect(assigns[:graph_list].length).to eq(5)
    # The first is the only one with raw values, the rest are
    # percentages with error bars:
    assigns[:graph_list].each_with_index do |graph, index|
      if index == 0
        expect(graph['errorbars']).to be false
        expect(graph['x_values'].length).to eq(4)
        expect(graph['x_values']).to eq([0, 1, 2, 3])
        expect(graph['y_values']).to eq([1, 2, 2, 4])
      else
        expect(graph['errorbars']).to be true
        # Just check the first one:
        if index == 1
          expect(graph['x_values']).to eq([0, 1, 2, 3])
          expect(graph['y_values']).to eq([0, 50, 100, 100])
        end
        # Check that at least every confidence interval value is
        # a Float (rather than NilClass, say):
        graph['cis_below'].each { |v| expect(v).to be_instance_of(Float) }
        graph['cis_above'].each { |v| expect(v).to be_instance_of(Float) }
      end
    end
  end

end

describe PublicBodyController, "when converting data for graphing" do

  before(:each) do
    @raw_count_data = PublicBody.get_request_totals(n=3,
                                                    highest=true,
                                                    minimum_requests=1)
    @percentages_data = PublicBody.get_request_percentages(
      column='info_requests_successful_count',
      n=3,
      highest=false,
    minimum_requests=1)
  end

  it "should not include the real public body model instance" do
    to_draw = controller.simplify_stats_for_graphs(@raw_count_data,
                                                   column='blah_blah',
                                                   percentages=false,
                                                   {} )
    expect(to_draw['public_bodies'][0].class).to eq(Hash)
    expect(to_draw['public_bodies'][0].has_key?('request_email')).to be false
  end

  it "should generate the expected id" do
    to_draw = controller.simplify_stats_for_graphs(@raw_count_data,
                                                   column='blah_blah',
                                                   percentages=false,
                                                   {:highest => true} )
    expect(to_draw['id']).to eq("blah_blah-highest")
    to_draw = controller.simplify_stats_for_graphs(@raw_count_data,
                                                   column='blah_blah',
                                                   percentages=false,
                                                   {:highest => false} )
    expect(to_draw['id']).to eq("blah_blah-lowest")
  end

  it "should have exactly the expected keys" do
    to_draw = controller.simplify_stats_for_graphs(@raw_count_data,
                                                   column='blah_blah',
                                                   percentages=false,
                                                   {} )
    expect(to_draw.keys.sort).to eq(["errorbars", "id", "public_bodies",
                                 "title", "tooltips", "totals",
                                 "x_axis", "x_ticks", "x_values",
                                 "y_axis", "y_max", "y_values"])

    to_draw = controller.simplify_stats_for_graphs(@percentages_data,
                                                   column='whatever',
                                                   percentages=true,
                                                   {})
    expect(to_draw.keys.sort).to eq(["cis_above", "cis_below",
                                 "errorbars", "id", "public_bodies",
                                 "title", "tooltips", "totals",
                                 "x_axis", "x_ticks", "x_values",
                                 "y_axis", "y_max", "y_values"])
  end

  it "should have values of the expected class and length" do
    [controller.simplify_stats_for_graphs(@raw_count_data,
                                          column='blah_blah',
                                          percentages=false,
                                          {}),
     controller.simplify_stats_for_graphs(@percentages_data,
                                          column='whatever',
                                          percentages=true,
    {})].each do |to_draw|
      per_pb_keys = ["cis_above", "cis_below", "public_bodies",
                     "tooltips", "totals", "x_ticks", "x_values",
                     "y_values"]
      # These should be all be arrays with one element per public body:
      per_pb_keys.each do |key|
        if to_draw.has_key? key
          expect(to_draw[key].class).to eq(Array)
          expect(to_draw[key].length).to eq(3), "for key #{key}"
        end
      end
      # Just check that the rest aren't of class Array:
      to_draw.keys.each do |key|
        unless per_pb_keys.include? key
          expect(to_draw[key].class).not_to eq(Array), "for key #{key}"
        end
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
    expect(response).to render_template('public_body/_search_ahead')
    expect(assigns[:xapian_requests]).to be_nil
  end

  it "should return a body matching the given keyword, but not users with a matching description" do
    get :search_typeahead, :query => "Geraldine"
    expect(response).to render_template('public_body/_search_ahead')
    expect(response.body).to include('search_ahead')
    expect(assigns[:xapian_requests].results.size).to eq(1)
    expect(assigns[:xapian_requests].results[0][:model].name).to eq(public_bodies(:geraldine_public_body).name)
  end

  it "should return all requests matching any of the given keywords" do
    get :search_typeahead, :query => "Geraldine Humpadinking"
    expect(response).to render_template('public_body/_search_ahead')
    expect(assigns[:xapian_requests].results.map{|x|x[:model]}).to match_array([
      public_bodies(:humpadink_public_body),
      public_bodies(:geraldine_public_body),
    ])
  end

  it "should return requests matching the given keywords in any of their locales" do
    get :search_typeahead, :query => "baguette" # part of the spanish notes
    expect(response).to render_template('public_body/_search_ahead')
    expect(assigns[:xapian_requests].results.map{|x|x[:model]}).to match_array([public_bodies(:humpadink_public_body)])
  end

  it "should not return  matches for short words" do
    get :search_typeahead, :query => "b"
    expect(response).to render_template('public_body/_search_ahead')
    expect(assigns[:xapian_requests]).to be_nil
  end

  it 'remembers the search params' do
    search_params = {
      'query'  => 'Quango',
      'page'   => '1',
      'bodies' => '1'
    }
    get :search_typeahead, search_params
    expect(flash[:search_params]).to eq(search_params)
  end

end
