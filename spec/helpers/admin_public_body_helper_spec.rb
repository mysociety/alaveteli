require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminPublicBodyHelper do

    include AdminPublicBodyHelper

    describe :public_body_form_object do

        context 'in the default locale' do

            before(:each) do
                @locale = I18n.default_locale
                @public_body = Factory.create(:public_body)
            end

            it 'provides the original object' do
                object = public_body_form_object(@public_body, @locale)[:object]
                expect(object).to eq(@public_body)
            end

            it 'provides the prefix public_body' do
                prefix = public_body_form_object(@public_body, @locale)[:prefix]
                expect(prefix).to eq('public_body')
            end

        end

        context 'in an alternative locale' do

            it 'provides the prefix public_body[translated_versions][]' do
                public_body = FactoryGirl.build(:public_body)
                locale = :es
                prefix = public_body_form_object(public_body, locale)[:prefix]
                expect(prefix).to eq('public_body[translated_versions][]')
            end

            context 'when the PublicBody is new' do

                it 'builds a new PublicBody::Translation' do
                    public_body = FactoryGirl.build(:public_body)
                    locale = :es

                    object = public_body_form_object(public_body, locale)[:object]

                    expect(object).to be_instance_of(PublicBody::Translation)
                    expect(object).to be_new_record
                end

            end

            context 'when the PublicBody has been persisted' do

                it 'finds an existing PublicBody::Translation for the locale' do
                    public_body = public_bodies(:geraldine_public_body)
                    locale = :es
                    translation = public_body.find_translation_by_locale(locale)

                    object = public_body_form_object(public_body, locale)[:object]

                    expect(object).to eq(translation)
                end

                it 'builds a new PublicBody::Translation if the record does not have one for that locale' do
                    public_body = FactoryGirl.create(:public_body)
                    locale = :es

                    object = public_body_form_object(public_body, locale)[:object]

                    expect(object).to be_instance_of(PublicBody::Translation)
                    expect(object).to be_new_record
                end

            end

        end

    end

end
