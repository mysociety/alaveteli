# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'fakeweb'

describe ServicesController, "when returning a message for people in other countries" do

  render_views

  # store and restore the locale in the context of the test suite to isolate
  # changes made in these tests
  before do
    @old_locale = FastGettext.locale
  end

  it 'keeps the flash' do
    # Make two get requests to simulate the flash getting swept after the
    # first response.
    get :other_country_message, nil, nil, :some_flash_key => 'abc'
    get :other_country_message
    expect(flash[:some_flash_key]).to eq('abc')
  end

  it "shows no alaveteli message when user in same country as deployed alaveteli" do
    allow(AlaveteliConfiguration).to receive(:iso_country_code).and_return("DE")
    allow(controller).to receive(:country_from_ip).and_return('DE')
    get :other_country_message
    expect(response.body).to eq("")
  end

  it "shows a message when user not in same country as deployed alaveteli and user country has no FOI website" do
    allow(AlaveteliConfiguration).to receive(:iso_country_code).and_return("DE")
    allow(controller).to receive(:country_from_ip).and_return('ZZ')
    get :other_country_message
    expect(response.body).to match(/outside Deutschland/)
  end

  it "shows a message when user not in same country as deployed alaveteli and user country has no FOI website
      and WorldFOIWebsites has no data about the deployed alaveteli" do
    allow(AlaveteliConfiguration).to receive(:iso_country_code).and_return("XY")
    allow(controller).to receive(:country_from_ip).and_return('ZZ')
    get :other_country_message
    expect(response.body).to match(/in other countries/)
  end

  it "shows an EU message if the user location has a deployed FOI website and is covered by AskTheEU" do
    allow(AlaveteliConfiguration).to receive(:iso_country_code).and_return("DE")
    allow(controller).to receive(:country_from_ip).and_return('ES')
    get :other_country_message
    expect(response.body).to match(/within España at/)
    expect(response.body).to match(/EU institutions/)
  end

  it "shows a message if user location has a deployed FOI website" do
    allow(AlaveteliConfiguration).to receive(:iso_country_code).and_return("ZZ")
    allow(controller).to receive(:country_from_ip).and_return('ES')
    get :other_country_message
    expect(response.body).
      to match(/You can make Freedom of Information requests within España at/)
  end

  after do
    FastGettext.set_locale(@old_locale)
  end

end
