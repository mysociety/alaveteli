# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: public_body_headings
#
#  id            :integer          not null, primary key
#  display_order :integer
#

require 'spec_helper'

describe PublicBodyHeading do

    context 'when validating' do

        it 'should require a name' do
            heading = PublicBodyHeading.new
            heading.should_not be_valid
            heading.errors[:name].should == ["Name can't be blank"]
        end

        it 'should require a unique name' do
            heading = FactoryGirl.create(:public_body_heading)
            new_heading = PublicBodyHeading.new(:name => heading.name)
            new_heading.should_not be_valid
            new_heading.errors[:name].should == ["Name is already taken"]
        end

        it 'should set a default display order based on the next available display order' do
            heading = PublicBodyHeading.new
            heading.valid?
            heading.display_order.should == PublicBodyHeading.next_display_order
        end

        it 'validates the translations' do
            heading = FactoryGirl.build(:public_body_heading)
            translation = heading.translations.build
            expect(heading).to_not be_valid
        end

    end

    context 'when setting a display order' do

        it 'should return 0 if there are no public body headings' do
            PublicBodyHeading.next_display_order.should == 0
        end

        it 'should return one more than the highest display order if there are public body headings' do
            heading = FactoryGirl.create(:public_body_heading)
            PublicBodyHeading.next_display_order.should == 1
        end
    end

    describe :save do

      it 'saves translations' do
          heading = FactoryGirl.build(:public_body_heading)
          heading.translations_attributes = { :es => { :locale => 'es',
                                                       :name => 'El Heading' } }

          heading.save
          expect(PublicBodyHeading.find(heading.id).translations.size).to eq(2)
      end

    end

    describe :translations_attributes= do

        context 'translation_attrs is a Hash' do

            it 'does not persist translations' do
                heading = FactoryGirl.create(:public_body_heading)
                heading.translations_attributes = { :es => { :locale => 'es',
                                                             :name => 'El Heading' } }

                expect(PublicBodyHeading.find(heading.id).translations.size).to eq(1)
            end

            it 'creates a new translation' do
                heading = FactoryGirl.create(:public_body_heading)
                heading.translations_attributes = { :es => { :locale => 'es',
                                                             :name => 'El Heading' } }
                heading.save
                heading.reload
                expect(heading.name(:es)).to eq('El Heading')
            end

            it 'updates an existing translation' do
                heading = FactoryGirl.create(:public_body_heading)
                heading.translations_attributes = { 'es' => { :locale => 'es',
                                                              :name => 'Name' } }
                heading.save

                heading.translations_attributes = { 'es' => { :id => heading.translation_for(:es).id,
                                                              :locale => 'es',
                                                              :name => 'Renamed' } }
                heading.save
                expect(heading.name(:es)).to eq('Renamed')
            end

            it 'updates an existing translation and creates a new translation' do
                heading = FactoryGirl.create(:public_body_heading)
                heading.translations.create(:locale => 'es',
                                             :name => 'Los Heading')

                expect(heading.translations.size).to eq(2)

                heading.translations_attributes = {
                    'es' => { :id => heading.translation_for(:es).id,
                              :locale => 'es',
                              :name => 'Renamed' },
                    'fr' => { :locale => 'fr',
                              :name => 'Le Heading' }
                }

                expect(heading.translations.size).to eq(3)
                I18n.with_locale(:es) { expect(heading.name).to eq('Renamed') }
                I18n.with_locale(:fr) { expect(heading.name).to eq('Le Heading') }
            end

            it 'skips empty translations' do
                heading = FactoryGirl.create(:public_body_heading)
                heading.translations.create(:locale => 'es',
                                             :name => 'Los Heading')

                expect(heading.translations.size).to eq(2)

                heading.translations_attributes = {
                    'es' => { :id => heading.translation_for(:es).id,
                              :locale => 'es',
                              :name => 'Renamed' },
                    'fr' => { :locale => 'fr' }
                }

                expect(heading.translations.size).to eq(2)
            end
        end
    end
end

describe PublicBodyHeading::Translation do

  it 'requires a locale' do
    translation = PublicBodyHeading::Translation.new
    translation.valid?
    expect(translation.errors[:locale]).to eq(["can't be blank"])
  end

  it 'is valid if all required attributes are assigned' do
    translation = PublicBodyHeading::Translation.new(:locale => I18n.default_locale)
    expect(translation).to be_valid
  end

end
