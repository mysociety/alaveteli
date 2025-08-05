# -*- encoding : utf-8 -*-
require 'spec_helper'
require File.expand_path(File.dirname(__FILE__) + '/alaveteli_dsl')

describe 'Adding a Public Body Category' do
  before do
    allow(AlaveteliConfiguration).to receive(:skip_admin_auth).and_return(false)

    confirm(:admin_user)
    @admin = login(:admin_user)
  end

  it 'can create a category when the default locale is an underscore locale' do
    AlaveteliLocalization.set_locales('en_GB es', 'en_GB')
    using_session(@admin) do
      visit new_admin_category_path
      fill_in 'public_body_category_title', :with => 'New Category en_GB'
      fill_in 'public_body_category_description', :with => 'Test'
      fill_in 'public_body_category_category_tag', :with => 'test'
      click_button 'Create'

      expect(page).to have_content('successfully created')
    end
  end

  it 'displays errors for title and description for the default locale' do
    AlaveteliLocalization.set_locales('en_GB es', 'en_GB')
    using_session(@admin) do
      visit new_admin_category_path
      click_button 'Create'

      expect(page).to have_content("Title can't be blank")
      expect(page).to have_content("Description can't be blank")
    end
  end

end
