# -*- encoding : utf-8 -*-
require 'spec_helper'
require File.expand_path(File.dirname(__FILE__) + '/alaveteli_dsl')

describe 'Adding a Public Body' do
  before do
    allow(AlaveteliConfiguration).to receive(:skip_admin_auth).and_return(false)

    confirm(:admin_user)
    @admin = login(:admin_user)
  end

  it 'can create a public body when the default locale is an underscore locale' do
    AlaveteliLocalization.set_locales('en_GB es', 'en_GB')
    using_session(@admin) do
      visit new_admin_body_path
      fill_in 'public_body_name', :with => 'New Public Body en_GB'
      click_button 'Create'

      expect(page).to have_content('successfully created')
    end
  end

end
