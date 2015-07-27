# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/alaveteli_dsl')

describe 'Editing a Public Body Category' do
  before do
    AlaveteliConfiguration.stub!(:skip_admin_auth).and_return(false)

    confirm(:admin_user)
    @admin = login(:admin_user)
    @category = FactoryGirl.create(:public_body_category)
  end

  it 'can edit the default locale' do
    @admin.visit edit_admin_category_path(@category)
    @admin.fill_in 'public_body_category_title__en', :with => 'New Category EN'
    @admin.click_button 'Save'

    @category.reload
    expect(@category.title).to eq('New Category EN')
  end

  it 'can add a translation for a single locale' do
    expect(@category.find_translation_by_locale('fr')).to be_nil

    @admin.visit edit_admin_category_path(@category)
    @admin.fill_in 'public_body_category_translations_attributes_fr_title__fr', :with => 'New Category FR'
    @admin.fill_in 'public_body_category_translations_attributes_fr_description__fr', :with => 'FR Description'
    @admin.click_button 'Save'

    @category.reload
    I18n.with_locale(:fr) do
      expect(@category.title).to eq('New Category FR')
    end
  end

  it 'can add a translation for multiple locales' do
    # Add FR translation
    @admin.visit edit_admin_category_path(@category)
    @admin.fill_in 'public_body_category_translations_attributes_fr_title__fr', :with => 'New Category FR'
    @admin.fill_in 'public_body_category_translations_attributes_fr_description__fr', :with => 'FR Description'
    @admin.click_button 'Save'

    # Add ES translation
    @admin.visit edit_admin_category_path(@category)
    @admin.fill_in 'public_body_category_translations_attributes_es_title__es', :with => 'New Category ES'
    @admin.fill_in 'public_body_category_translations_attributes_es_description__es', :with => 'ES Description'
    @admin.click_button 'Save'

    @category.reload
    I18n.with_locale(:fr) do
      expect(@category.title).to eq('New Category FR')
    end

    I18n.with_locale(:es) do
      expect(@category.title).to eq('New Category ES')
    end
  end

end
