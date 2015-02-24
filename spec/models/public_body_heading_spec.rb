# == Schema Information
#
# Table name: public_body_headings
#
#  id            :integer          not null, primary key
#  display_order :integer
#

require 'spec_helper'

describe PublicBodyHeading do

    context 'when loading the data' do

        before do
            PublicBodyCategory.add(:en, [
                  "Local and regional",
                      [ "local_council", "Local councils", "a local council" ],
                  "Miscellaneous",
                      [ "other", "Miscellaneous", "miscellaneous" ],])
        end

        it 'should use the display_order field to preserve the original data order' do
            headings = PublicBodyHeading.all
            headings[0].name.should eq 'Local and regional'
            headings[0].display_order.should eq 0
            headings[1].name.should eq 'Miscellaneous'
            headings[1].display_order.should eq 1
        end

    end

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

    describe :translations_attributes= do

        context 'translation_attrs is a Hash' do

            it 'takes the correct code path for a Hash' do
                attrs = {}
                attrs.should_receive(:each_value)
                PublicBodyHeading.new().translations_attributes = attrs
            end

            it 'updates an existing translation' do
                heading = FactoryGirl.create(:public_body_heading)
                params = { 'es' => { :locale => 'es',
                                     :name => 'Renamed' } }

                heading.translations_attributes = params
                I18n.with_locale(:es) { expect(heading.name).to eq('Renamed') }
            end

            it 'updates an existing translation and creates a new translation' do
                heading = FactoryGirl.create(:public_body_heading)
                heading.translations.create(:locale => 'es',
                                            :name => 'Los Heading')

                expect(heading.translations.size).to eq(2)

                heading.translations_attributes = {
                    'es' => { :locale => 'es',
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
                    'es' => { :locale => 'es',
                              :name => 'Los Heading' },
                    'fr' => { :locale => 'fr' }
                }

                expect(heading.translations.size).to eq(2)
            end

        end
    end

end
