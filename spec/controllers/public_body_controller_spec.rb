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
    get :show, params: { :url_name => "dfh", :view => 'all' }
    expect(response).to be_success
  end

  it "should render with 'show' template" do
    get :show, params: { :url_name => "dfh", :view => 'all' }
    expect(response).to render_template('show')
  end

  it "should assign the body" do
    get :show, params: { :url_name => "dfh", :view => 'all' }
    expect(assigns[:public_body]).to eq(public_bodies(:humpadink_public_body))
  end

  it "should assign the requests (1)" do
    get :show, params: { :url_name => "tgq", :view => 'all' }
    conditions = { :public_body_id => public_bodies(:geraldine_public_body).id }
    actual = assigns[:xapian_requests].results.map{ |x| x[:model].info_request }
    expect(actual).to match_array(InfoRequest.where(conditions))
  end

  it "should assign the requests (2)" do
    get :show, params: { :url_name => "tgq", :view => 'successful' }
    conditions = { :described_state => 'successful',
                   :public_body_id => public_bodies(:geraldine_public_body).id }
    actual = assigns[:xapian_requests].results.map{ |x| x[:model].info_request }
    expect(actual).to match_array(InfoRequest.where(conditions))
  end

  it "should assign the requests (3)" do
    get :show, params: { :url_name => "dfh", :view => 'all' }
    conditions = { :public_body_id => public_bodies(:humpadink_public_body).id }
    actual = assigns[:xapian_requests].results.map{ |x| x[:model].info_request }
    expect(actual).to match_array(InfoRequest.where(conditions))
  end

  it "should display the body using same locale as that used in url_name" do
    get :show, params: { :url_name => "edfh", :view => 'all', :locale => "es" }
    expect(response.body).to have_content("Baguette")
  end

  it 'should show public body names in the selected locale language if present for a locale with underscores' do
    AlaveteliLocalization.set_locales('he_IL en', 'en')
    get :show, params: { :url_name => 'dfh',
                         :view => 'all',
                         :locale => 'he_IL' }
    expect(response.body).to have_content('Hebrew Humpadinking')
  end

  it "should redirect use to the relevant locale even when url_name is for a different locale" do
    get :show, params: { :url_name => "edfh", :view => 'all' }
    expect(response).to redirect_to "http://test.host/body/dfh"
  end

  it "should redirect to newest name if you use historic name of public body in URL" do
    get :show, params: { :url_name => "hdink", :view => 'all' }
    expect(response).to redirect_to(:controller => 'public_body', :action => 'show', :url_name => "dfh")
  end

  it "should redirect to lower case name if you use mixed case name in URL" do
    get :show, params: { :url_name => "dFh", :view => 'all' }
    expect(response).to redirect_to(:controller => 'public_body', :action => 'show', :url_name => "dfh")
  end

  it 'keeps the search_params flash' do
    # Make two get requests to simulate the flash getting swept after the
    # first response.
    search_params = { 'query' => 'Quango' }
    get :show, params: { :url_name => 'dfh', :view => 'all' },
               flash: { :search_params => search_params }
    get :show, params: { :url_name => 'dfh', :view => 'all' }
    expect(flash[:search_params]).to eq(search_params)
  end


  it 'should not show high page offsets as these are extremely slow to generate' do
    expect {
      get :show, params: { :url_name => 'dfh', :view => 'all', :page => 25 }
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'should not raise an error when given an empty query param' do
    get :show, params: { :url_name => "dfh", :view => 'all', :query => nil }
    expect(response).to be_success
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
      AlaveteliLocalization.with_locale(locale) do
        case locale
        when :en
          result = PublicBody.new(:name => 'English only',
                                  :short_name => 'EO')
        when :es
          result = PublicBody.new(:name => 'Español Solamente',
                                  :short_name => 'ES')
        when :en_GB
          result = PublicBody.new(:name => 'GB English',
                                  :short_name => 'GB')
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
    get :list, params: { :locale => 'es' }
    expect(assigns[:public_bodies].include?(@english_only)).to eq(false)
    expect(assigns[:public_bodies].include?(@spanish_only)).to eq(true)
  end

  it "if fallback is requested, should list all bodies from default locale, even when there are no translations for selected locale" do
    allow(AlaveteliConfiguration).to receive(:public_body_list_fallback_to_default_locale).and_return(true)
    @english_only = make_single_language_example :en
    get :list, params: { :locale => 'es' }
    expect(assigns[:public_bodies].include?(@english_only)).to eq(true)
  end

  it 'if fallback is requested, should still list public bodies only with translations in the current locale' do
    allow(AlaveteliConfiguration).to receive(:public_body_list_fallback_to_default_locale).and_return(true)
    @spanish_only = make_single_language_example :es
    get :list, params: { :locale => 'es' }
    expect(assigns[:public_bodies].include?(@spanish_only)).to eq(true)
  end

  it "if fallback is requested, make sure that there are no duplicates listed" do
    allow(AlaveteliConfiguration).to receive(:public_body_list_fallback_to_default_locale).and_return(true)
    get :list, params: { :locale => 'es' }
    pb_ids = assigns[:public_bodies].map { |pb| pb.id }
    unique_pb_ids = pb_ids.uniq
    expect(pb_ids.sort).to be === unique_pb_ids.sort
  end

  it 'should show public body names in the selected locale language if present' do
    get :list, params: { :locale => 'es' }
    expect(response.body).to have_content('El Department for Humpadinking')
  end

  it 'show public body names of the selected underscore locale language' do
    AlaveteliLocalization.set_locales(available_locales='en en_GB',
                                      default_locale='en')
    @gb_only = make_single_language_example :en_GB
    get :list, params: { :locale => 'en_GB' }
    expect(response.body).to have_content(@gb_only.name)
  end

  it 'should not show the internal admin authority' do
    PublicBody.internal_admin_body
    get :list, params: { :locale => 'en' }
    expect(response.body).not_to have_content('Internal admin authority')
  end

  it 'should order on the translated name, even with the fallback' do
    # The names of each public body is in:
    #    <span class="head"><a>Public Body Name</a></span>
    # ... eo extract all of those, and check that they are ordered:
    allow(AlaveteliConfiguration).to receive(:public_body_list_fallback_to_default_locale).and_return(true)
    get :list, params: { :locale => 'es' }
    parsed = Nokogiri::HTML(response.body)
    public_body_names = parsed.xpath '//span[@class="head"]/a/text()'
    public_body_names = public_body_names.map { |pb| pb.to_s }
    expect(public_body_names).to eq(public_body_names.sort)
  end

  it 'should show public body names in the selected locale language if present for a locale with underscores' do
    AlaveteliLocalization.set_locales('he_IL en', 'en')
    get :list, params: { :locale => 'he_IL' }
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
    expect(assigns[:description]).to eq("Found 6 public authorities")
  end

  it 'list bodies in collate order according to the locale with the fallback set' do
    allow(AlaveteliConfiguration).to receive(:public_body_list_fallback_to_default_locale).
      and_return(true)

    allow(DatabaseCollation).to receive(:supports?).
      with(an_instance_of(String)).
        and_return(true)

    get :list, params: { :locale => 'en_GB' }
    expect(assigns[:public_bodies].to_sql).to include('COLLATE')
  end

  it 'list bodies in default order according to the locale with the fallback set' do
    allow(AlaveteliConfiguration).to receive(:public_body_list_fallback_to_default_locale).
      and_return(true)

    allow(DatabaseCollation).to receive(:supports?).
      with(an_instance_of(String)).
        and_return(false)

    get :list, params: { :locale => 'unknown' }

    expect(assigns[:public_bodies].to_sql).to_not include('COLLATE')
  end

  it 'list bodies in collate order according to the locale' do
    allow(AlaveteliConfiguration).to receive(:public_body_list_fallback_to_default_locale).
      and_return(false)

    allow(DatabaseCollation).to receive(:supports?).
      with(an_instance_of(String)).
        and_return(true)

    get :list, params: { :locale => 'en_GB' }

    expect(assigns[:public_bodies].to_sql).to include('COLLATE')
  end

  it 'list bodies in alphabetical order according to the locale' do
    allow(AlaveteliConfiguration).to receive(:public_body_list_fallback_to_default_locale).
      and_return(false)

    allow(DatabaseCollation).to receive(:supports?).
      with(an_instance_of(String)).
        and_return(false)

    get :list, params: { :locale => 'unknown' }

    expect(assigns[:public_bodies].to_sql).to_not include('COLLATE')
  end

  it "should support simple searching of bodies by title" do
    get :list, params: { :public_body_query => 'quango' }
    expect(assigns[:public_bodies]).to eq([ public_bodies(:geraldine_public_body) ])
  end

  it "should support simple searching of bodies by short_name" do
    get :list, params: { :public_body_query => 'DfH' }
    expect(assigns[:public_bodies]).to eq([ public_bodies(:humpadink_public_body) ])
  end

  it "should support simple searching of bodies by notes" do
    get :list, params: { :public_body_query => 'Albatross' }
    expect(assigns[:public_bodies]).to eq([ public_bodies(:humpadink_public_body) ])
  end

  it "should list bodies in alphabetical order with different locale" do
    with_default_locale(:es) do
      get :list
      expect(response).to render_template('list')
      expect(assigns[:public_bodies]).to eq([ public_bodies(:geraldine_public_body), public_bodies(:humpadink_public_body) ])
      expect(assigns[:tag]).to eq("all")
      expect(assigns[:description]).to eq("Found 2 public authorities")
    end
  end

  it "should list a tagged thing on the appropriate list page, and others on the other page,
        and all still on the all page" do
    PublicBodyCategory.destroy_all
    PublicBodyHeading.destroy_all
    PublicBodyCategoryLink.destroy_all

    category = FactoryBot.create(:public_body_category)
    heading = FactoryBot.create(:public_body_heading)
    PublicBodyCategoryLink.create(:public_body_heading_id => heading.id,
                                  :public_body_category_id => category.id)
    public_bodies(:humpadink_public_body).tag_string = category.category_tag

    get :list, params: { :tag => category.category_tag }
    expect(response).to render_template('list')
    expect(assigns[:public_bodies]).to eq([ public_bodies(:humpadink_public_body) ])
    expect(assigns[:tag]).to eq(category.category_tag)
    expect(assigns[:description]).
      to eq("Found 1 public authority in the category ‘#{category.title}’")

    get :list, params: { :tag => "other" }
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

    get :list, params: { :tag => "eats_cheese" }
    expect(response).to render_template('list')
    expect(assigns[:public_bodies]).to eq([ public_bodies(:humpadink_public_body) ])
    expect(assigns[:tag]).to eq("eats_cheese")

    get :list, params: { :tag => "eats_cheese:jarlsberg" }
    expect(response).to render_template('list')
    expect(assigns[:public_bodies]).to eq([ ])
    expect(assigns[:tag]).to eq("eats_cheese:jarlsberg")

    get :list, params: { :tag => "eats_cheese:stilton" }
    expect(response).to render_template('list')
    expect(assigns[:public_bodies]).to eq([ public_bodies(:humpadink_public_body) ])
    expect(assigns[:tag]).to eq("eats_cheese:stilton")
  end

  it 'should not include hidden requests in the request count' do
    fake_pb = FactoryBot.create(:public_body)
    hidden_request = FactoryBot.create(:info_request,
                                       :prominence => 'hidden',
                                       :public_body => fake_pb)
    visible_request = FactoryBot.create(:info_request, :public_body => fake_pb)
    fake_pb.reload
    expect(fake_pb.info_requests.size).to eq(2)
    expect(fake_pb.info_requests.is_searchable.size).to eq(1)
    fake_list = PublicBody.where(id: fake_pb.id)
    allow(fake_list).to receive(:with_tag).and_return(fake_list)
    allow(fake_list).to receive(:with_query).and_return(fake_list)
    allow(fake_list).to receive(:joins).and_return(fake_list)
    allow(fake_list).to receive(:paginate).and_return(fake_list)
    allow(fake_list).to receive(:order).and_return(fake_list)
    allow(fake_list).to receive(:total_entries).and_return(1)
    allow(fake_list).to receive(:total_pages).and_return(1)

    allow(PublicBody).to receive(:where).and_return(fake_list)
    get :list
    expect(response.body).to have_content('1 request.')
  end

  it 'raises an UnknownFormat error if asked for a json version of a list' do
    expect {
      get :list, params: { :format => 'json' }
    }.to raise_error(ActionController::UnknownFormat)
  end

  it "should list authorities starting with a multibyte first letter" do
    AlaveteliLocalization.set_locales('cs', 'cs')

    authority = AlaveteliLocalization.with_locale(:cs) do
      FactoryBot.create(:public_body, name: "Åčçèñtéd Authority")
    end

    get :list, params: { :tag => "å", :locale => 'cs' }
    expect(response).to render_template('list')
    expect(assigns[:public_bodies]).to eq([ authority ])
    expect(assigns[:tag]).to eq("Å")
  end

end

describe PublicBodyController, "when showing JSON version for API" do

  it "should be successful" do
    get :show, params: { :url_name => "dfh", :format => "json", :view => 'all' }

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
    expect(all_data.length).to eq(7)
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
    FactoryBot.create(:public_body,
                       :name => 'Site Admin Body',
                       :tag_string => 'site_administration')

    get :list_all_csv

    all_data = CSV.parse(response.body)
    expect(all_data.any?{ |row| row.include?('Site Admin Body') }).to be false
  end

end

describe PublicBodyController, "when doing type ahead searches" do
  render_views

  before(:each) do
    load_raw_emails_data
    get_fixtures_xapian_index
  end

  it 'renders the search_ahead template' do
    get :search_typeahead, params: { :query => "" }
    expect(response).to render_template('public_body/_search_ahead')
  end

  it 'assigns the xapian search to the view as xapian_requests' do
    get :search_typeahead, params: { :query => "Geraldine Humpadinking" }
    expect(assigns[:xapian_requests]).to be_an_instance_of ActsAsXapian::Search
  end

  it "shows the number of bodies matching the keywords" do
    get :search_typeahead, params: { :query => "Geraldine Humpadinking" }
    expect(response.body).to match("2 matching authorities")
  end

  it 'remembers the search params' do
    search_params = {
      'query'  => 'Quango',
      'page'   => '1',
      'bodies' => '1'
    }
    get :search_typeahead, params: search_params
    flash_params =
      if rails5?
        flash[:search_params].to_unsafe_h
      else
        flash[:search_params]
      end
    expect(flash_params).to eq(search_params)
  end

end
