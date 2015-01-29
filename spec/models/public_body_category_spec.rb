# == Schema Information
#
# Table name: public_body_categories
#
#  id           :integer          not null, primary key
#  category_tag :text             not null
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PublicBodyCategory do
    describe 'when loading the data' do
        it 'should use the display_order field to preserve the original data order' do
            PublicBodyCategory.add(:en, [
                "Local and regional",
                    [ "local_council", "Local councils", "a local council" ],
                "Miscellaneous",
                    [ "other", "Miscellaneous", "miscellaneous" ],
                    [ "aardvark", "Aardvark", "daft test"],])

            headings = PublicBodyHeading.all
            cat_group1 = headings[0].public_body_categories
            cat_group1.count.should eq 1
            cat_group1[0].title.should eq "Local councils"

            cat_group2 = headings[1].public_body_categories
            cat_group2.count.should eq 2
            cat_group2[0].title.should eq "Miscellaneous"
            cat_group2[0].public_body_category_links.where(
                :public_body_heading_id => headings[1].id).
                    first.
                    category_display_order.should eq 0

            cat_group2[1].title.should eq "Aardvark"
            cat_group2[1].public_body_category_links.where(
                :public_body_heading_id => headings[1].id).
                    first.
                    category_display_order.should eq 1
        end
    end

    context 'when validating' do

        it 'should require a title' do
            category = PublicBodyCategory.new
            category.should_not be_valid
            category.errors[:title].should == ["Title can't be blank"]
        end

        it 'should require a category tag' do
            category = PublicBodyCategory.new
            category.should_not be_valid
            category.errors[:category_tag].should == ["Tag can't be blank"]
        end

        it 'should require a unique tag' do
            existing = FactoryGirl.create(:public_body_category)
            PublicBodyCategory.new(:email => existing.category_tag).should_not be_valid
        end

        it 'should require a description' do
            category = PublicBodyCategory.new
            category.should_not be_valid
            category.errors[:description].should == ["Description can't be blank"]
        end
    end

    describe :translations_attributes= do

        context 'translation_attrs is a Hash' do

            it 'takes the correct code path for a Hash' do
                attrs = {}
                attrs.should_receive(:each_value)
                PublicBodyCategory.new().translations_attributes = attrs
            end

            it 'updates an existing translation' do
                category = FactoryGirl.create(:public_body_category)
                params = { 'es' => { :locale => 'es',
                                     :title => 'Renamed' } }

                category.translations_attributes = params
                I18n.with_locale(:es) { expect(category.title).to eq('Renamed') }
            end

            it 'updates an existing translation and creates a new translation' do
                category = FactoryGirl.create(:public_body_category)
                category.translations.create(:locale => 'es',
                                             :title => 'Los Category',
                                             :description => 'ES Description')

                expect(category.translations.size).to eq(2)

                category.translations_attributes = {
                    'es' => { :locale => 'es',
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
                    'es' => { :locale => 'es',
                              :title => 'Renamed' },
                    'fr' => { :locale => 'fr' }
                }

                expect(category.translations.size).to eq(2)
            end

        end
    end

end
