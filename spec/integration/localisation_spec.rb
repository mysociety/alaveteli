# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "when generating urls" do

    before do
        @home_link_regex = /href=".*\/en\//
    end

    it "should generate URLs that include the locale when using one that includes an underscore" do
        get('/en_GB')
        response.body.should match /href="\/en_GB\//
    end

    it "should fall back to the language if the territory is unknown" do
        AlaveteliLocalization.set_locales(available_locales='es en', default_locale='en')
        get('/', {}, {'HTTP_ACCEPT_LANGUAGE' => 'en_US'})
        response.body.should match /href="\/en\//
        response.body.should_not match /href="\/en_US\//
    end

    it "should generate URLs without a locale prepended when there's only one locale set" do
        AlaveteliLocalization.set_locales(available_locales='en', default_locale='en')
        get('/')
        response.should_not contain @home_link_regex
    end

    context 'when handling public body requests' do

        before do
            AlaveteliLocalization.set_locales(available_locales='es en', default_locale='en')
            body = FactoryGirl.create(:public_body, :short_name => 'english_short')
            I18n.with_locale(:es) do
                body.short_name = 'spanish_short'
                body.save!
            end
        end

        it 'should redirect requests for a public body in a locale to the
            canonical name in that locale' do
            get('/es/body/english_short')
            response.should redirect_to "/es/body/spanish_short"
        end

        it 'should remember a filter view when redirecting a public body
            request to the canonical name' do
            AlaveteliLocalization.set_locales(available_locales='es en', default_locale='en')
            get('/es/body/english_short/successful')
            response.should redirect_to "/es/body/spanish_short/successful"
        end
    end

    describe 'when there is more than one locale' do

        before do
            AlaveteliLocalization.set_locales(available_locales='es en', default_locale='en')
        end

        it "should generate URLs with a locale prepended when there's more than one locale set" do
            get('/')
            response.body.should match @home_link_regex
        end

        describe 'when using the default locale' do

            before do
                @default_lang_home_link = /href=".*\/en\//
                @other_lang_home_link = /href=".*\/es\//
                @old_include_default_locale_in_urls = AlaveteliConfiguration::include_default_locale_in_urls
            end

            describe 'when the config value INCLUDE_DEFAULT_LOCALE_IN_URLS is false' do

                before do
                    AlaveteliLocalization.set_default_locale_urls(false)
                end

                it 'should generate URLs without a locale prepended' do
                    get '/'
                    response.should_not contain @default_lang_home_link
                end

                it 'should render the front page in the default language when no locale param
                    is present and the session locale is not the default' do
                    get('/', {:locale => 'es'})
                    response.should_not contain @other_lang_home_link
                end
            end

            it 'should generate URLs with a locale prepended when the config value
                INCLUDE_DEFAULT_LOCALE_IN_URLS is true' do
                AlaveteliLocalization.set_default_locale_urls(true)
                get '/'
                response.body.should match /#{@default_lang_home_link}/
            end

            after do
                AlaveteliLocalization.set_default_locale_urls(@old_include_default_locale_in_urls)
            end

        end
    end

end
