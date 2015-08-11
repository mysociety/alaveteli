# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/alaveteli_dsl')

describe 'Editing a Public Body Category' do
  before do
    allow(AlaveteliConfiguration).to receive(:skip_admin_auth).and_return(false)

    confirm(:admin_user)
    @admin = login(:admin_user)
    @category = FactoryGirl.create(:public_body_category)
  end

  it 'can edit the default locale' do
    using_session(@admin) do
      visit edit_admin_category_path(@category)
      fill_in 'public_body_category_title__en', :with => 'New Category EN'
      click_button 'Save'
    end

    @category.reload
    expect(@category.title).to eq('New Category EN')
  end

  it 'can add a translation for a single locale' do
    expect(@category.find_translation_by_locale('fr')).to be_nil

    using_session(@admin) do
      visit edit_admin_category_path(@category)
      fill_in 'public_body_category_translations_attributes_fr_title__fr', :with => 'New Category FR'
      fill_in 'public_body_category_translations_attributes_fr_description__fr', :with => 'FR Description'
      click_button 'Save'
    end

    @category.reload
    I18n.with_locale(:fr) do
      expect(@category.title).to eq('New Category FR')
    end
  end

  it 'can add a translation for multiple locales' do
    using_session(@admin) do
      # Add FR translation
      visit edit_admin_category_path(@category)
      fill_in 'public_body_category_translations_attributes_fr_title__fr', :with => 'New Category FR'
      fill_in 'public_body_category_translations_attributes_fr_description__fr', :with => 'FR Description'
      click_button 'Save'

      # Add ES translation
      visit edit_admin_category_path(@category)
      fill_in 'public_body_category_translations_attributes_es_title__es', :with => 'New Category ES'
      fill_in 'public_body_category_translations_attributes_es_description__es', :with => 'ES Description'
      click_button 'Save'

    end
    @category.reload
    I18n.with_locale(:fr) do
      expect(@category.title).to eq('New Category FR')
    end

    I18n.with_locale(:es) do
      expect(@category.title).to eq('New Category ES')
    end
  end

end
