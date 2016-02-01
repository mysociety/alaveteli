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

  it "should show no alaveteli message when in the deployed country" do
    allow(AlaveteliConfiguration).to receive(:iso_country_code).and_return("DE")
    allow(controller).to receive(:country_from_ip).and_return('DE')
    get :other_country_message
    expect(response.body).to eq("")
  end

  it "should show an alaveteli message when not in the deployed country and in a country with no FOI website" do
    allow(AlaveteliConfiguration).to receive(:iso_country_code).and_return("DE")
    allow(controller).to receive(:country_from_ip).and_return('ZZ')
    get :other_country_message
    expect(response.body).to match(/outside Deutschland/)
  end

  it "shows an EU message if the country is covered by AskTheEU" do
    allow(AlaveteliConfiguration).to receive(:iso_country_code).and_return("DE")
    allow(controller).to receive(:country_from_ip).and_return('ES')
    get :other_country_message
    expect(response.body).to match(/within España at/)
    expect(response.body).to match(/EU institutions/)
  end

  it "should show link to other FOI website when not in the deployed country" do
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
