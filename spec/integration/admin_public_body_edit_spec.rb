# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/alaveteli_dsl')

describe 'Editing a Public Body' do
  before do
    AlaveteliConfiguration.stub!(:skip_admin_auth).and_return(false)

    confirm(:admin_user)
    @admin = login(:admin_user)

    PublicBody.create(:name => 'New Quango',
                      :short_name => '',
                      :request_email => 'newquango@localhost',
                      :last_edit_editor => 'test',
                      :last_edit_comment => 'testing')

    @body = PublicBody.find_by_name('New Quango')
  end

  it 'can edit the default locale' do
    @admin.visit edit_admin_body_path(@body)
    @admin.fill_in 'public_body_name__en', :with => 'New Quango EN'
    @admin.click_button 'Save'

    pb = @body.reload
    expect(pb.name).to eq('New Quango EN')
  end

  it 'can add a translation for a single locale' do
    expect(@body.find_translation_by_locale('fr')).to be_nil

    @admin.visit edit_admin_body_path(@body)
    @admin.fill_in 'public_body_translations_attributes_fr_name__fr', :with => 'New Quango FR'
    @admin.click_button 'Save'

    pb = @body.reload
    I18n.with_locale(:fr) do
      expect(pb.name).to eq('New Quango FR')
    end
  end

  it 'can add a translation for multiple locales' do
    @admin.visit edit_admin_body_path(@body)
    @admin.fill_in 'public_body_name__en', :with => 'New Quango EN'
    @admin.click_button 'Save'

    # Add FR translation
    expect(@body.find_translation_by_locale('fr')).to be_nil
    @admin.visit edit_admin_body_path(@body)
    @admin.fill_in 'public_body_translations_attributes_fr_name__fr', :with => 'New Quango FR'
    @admin.click_button 'Save'

    # Add ES translation
    expect(@body.find_translation_by_locale('es')).to be_nil
    @admin.visit edit_admin_body_path(@body)
    @admin.fill_in 'public_body_translations_attributes_es_name__es', :with => 'New Quango ES'
    @admin.click_button 'Save'

    pb = @body.reload

    expect(pb.name).to eq('New Quango EN')

    I18n.with_locale(:fr) do
      expect(pb.name).to eq('New Quango FR')
    end

    I18n.with_locale(:es) do
      expect(pb.name).to eq('New Quango ES')
    end
  end
end
