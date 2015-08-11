# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: public_body_categories
#
#  id           :integer          not null, primary key
#  category_tag :text             not null
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PublicBodyCategory do

  context 'when validating' do

    it 'should require a title' do
      category = PublicBodyCategory.new
      expect(category).not_to be_valid
      expect(category.errors[:title]).to eq(["Title can't be blank"])
    end

    it 'should require a category tag' do
      category = PublicBodyCategory.new
      expect(category).not_to be_valid
      expect(category.errors[:category_tag]).to eq(["Tag can't be blank"])
    end

    it 'should require a unique tag' do
      existing = FactoryGirl.create(:public_body_category)
      expect(PublicBodyCategory.new(:email => existing.category_tag)).not_to be_valid
    end

    it 'should require a description' do
      category = PublicBodyCategory.new
      expect(category).not_to be_valid
      expect(category.errors[:description]).to eq(["Description can't be blank"])
    end

    it 'validates the translations' do
      category = FactoryGirl.build(:public_body_category)
      translation = category.translations.build
      expect(category).to_not be_valid
    end

    it 'uses the base model validation for the default locale' do
      category = PublicBodyCategory.new
      translation = category.translations.build(:locale => 'en',
                                                :description => 'No title')
      category.valid?
      translation.valid?
      expect(category.errors[:title].size).to eq(1)
      expect(translation.errors[:title].size).to eq(0)
    end

  end

  describe '#save' do

    it 'saves translations' do
      category = FactoryGirl.build(:public_body_category)
      category.translations_attributes = { :es => { :locale => 'es',
                                                    :title => 'El Category',
                                                    :description => 'Spanish description' } }

      category.save
      expect(PublicBodyCategory.find(category.id).translations.size).to eq(2)
    end

  end

  describe '#translations_attributes=' do

    context 'translation_attrs is a Hash' do

      it 'does not persist translations' do
        category = FactoryGirl.create(:public_body_category)
        category.translations_attributes = { :es => { :locale => 'es',
                                                      :title => 'El Category',
                                                      :description => 'Spanish description' } }

        expect(PublicBodyCategory.find(category.id).translations.size).to eq(1)
      end

      it 'creates a new translation' do
        category = FactoryGirl.create(:public_body_category)
        category.translations_attributes = { :es => { :locale => 'es',
                                                      :title => 'El Category',
                                                      :description => 'Spanish description' } }
        category.save
        category.reload
        expect(category.title(:es)).to eq('El Category')
      end

      it 'updates an existing translation' do
        category = FactoryGirl.create(:public_body_category)
        category.translations_attributes = { 'es' => { :locale => 'es',
                                                       :title => 'Name',
                                                       :description => 'Desc' } }
        category.save

        category.translations_attributes = { 'es' => { :id => category.translation_for(:es).id,
                                                       :locale => 'es',
                                                       :title => 'Renamed',
                                                       :description => 'Desc' } }
        category.save
        expect(category.title(:es)).to eq('Renamed')
      end

      it 'updates an existing translation and creates a new translation' do
        category = FactoryGirl.create(:public_body_category)
        category.translations.create(:locale => 'es',
                                     :title => 'Los Category',
                                     :description => 'ES Description')

        expect(category.translations.size).to eq(2)

        category.translations_attributes = {
          'es' => { :id => category.translation_for(:es).id,
                    :locale => 'es',
                    :title => 'Renamed' },
          'fr' => { :locale => 'fr',
                    :title => 'Le Category' }
        }

        expect(category.translations.size).to eq(3)
        I18n.with_locale(:es) { expect(category.title).to eq('Renamed') }
        I18n.with_locale(:fr) { expect(category.title).to eq('Le Category') }
      end

      it 'skips empty translations' do
        category = FactoryGirl.create(:public_body_category)
        category.translations.create(:locale => 'es',
                                     :title => 'Los Category',
                                     :description => 'ES Description')

        expect(category.translations.size).to eq(2)

        category.translations_attributes = {
          'es' => { :id => category.translation_for(:es).id,
                    :locale => 'es',
                    :title => 'Renamed' },
          'fr' => { :locale => 'fr' }
        }

        expect(category.translations.size).to eq(2)
      end

    end
  end

end

describe PublicBodyCategory::Translation do

  it 'requires a locale' do
    translation = PublicBodyCategory::Translation.new
    translation.valid?
    expect(translation.errors[:locale]).to eq(["can't be blank"])
  end

  it 'is valid if no required attributes are assigned' do
    translation = PublicBodyCategory::Translation.new(:locale => I18n.default_locale)
    expect(translation).to be_valid
  end

  it 'requires a title if another required attribute is assigned' do
    translation = PublicBodyCategory::Translation.new(:description => 'spec')
    translation.valid?
    expect(translation.errors[:title]).to eq(["Title can't be blank"])
  end

  it 'requires a description if another required attribute is assigned' do
    translation = PublicBodyCategory::Translation.new(:title => 'spec')
    translation.valid?
    expect(translation.errors[:description]).to eq(["Description can't be blank"])
  end

end
