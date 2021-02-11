require 'spec_helper'

describe Admin::TranslatedRecordForm do
  let(:builder) { described_class.new(:mock, resource, template, {}) }
  let(:template) { self }

  let(:resource) do
    AlaveteliLocalization.with_default_locale do
      FactoryBot.create(:public_body_heading, name: 'Foo')
    end
  end

  describe '#translated_fields' do
    subject do
      builder.translated_fields { |t| template.concat(t.text_field(:name)) }
    end

    context 'with a single locale' do
      let(:html) do
        <<~HTML.gsub(/\n\s*/, '').strip
        <div id="div-locales">
          <ul class="locales nav nav-tabs">
            <li><a data-toggle="tab" href="#div-locale-en">English</a></li>
          </ul>
          <div class="tab-content">
            <div id="div-locale-en" class="tab-pane">
              <input value="en" type="hidden" name="public_body_heading[locale]" id="public_body_heading_locale" />
              <input type="text" value="Foo" name="public_body_heading[name]" id="public_body_heading_name" />
            </div>
          </div>
        </div>
        HTML
      end

      it { is_expected.to eq(html) }
    end

    context 'with multiple locales' do
      before do
        AlaveteliLocalization.with_locale(:es) do
          resource.update(name: 'El Foo')
        end

        @translation_id = resource.translations.find_by(locale: 'es')&.id
      end

      let(:html) do
        <<~HTML.gsub(/\n\s*/, '').strip
        <div id="div-locales">
          <ul class="locales nav nav-tabs">
            <li><a data-toggle="tab" href="#div-locale-en">English</a></li>
            <li><a data-toggle="tab" href="#div-locale-es">español</a></li>
          </ul>
          <div class="tab-content">
            <div id="div-locale-en" class="tab-pane">
              <input value="en" type="hidden" name="public_body_heading[locale]" id="public_body_heading_locale" />
              <input type="text" value="Foo" name="public_body_heading[name]" id="public_body_heading_name" />
            </div>
            <div id="div-locale-es" class="tab-pane">
              <input value="es" type="hidden" name="mock[translations_attributes][es][locale]" id="mock_translations_attributes_es_locale" />
              <input type="text" value="El Foo" name="mock[translations_attributes][es][name]" id="mock_translations_attributes_es_name" />
              <input type="hidden" value="#{@translation_id}" name="mock[translations_attributes][es][id]" id="mock_translations_attributes_es_id" />
            </div>
          </div>
        </div>
        HTML
      end

      it { is_expected.to eq(html) }
    end
  end
end
