require 'spec_helper'

RSpec.describe Admin::TranslatedRecordHelper, type: :helper do
  describe '#translated_form_for' do
    let(:record) { FactoryBot.build(:announcement) }

    it 'uses a custom form builder' do
      helper.translated_form_for(record, url: '#') do |f|
        expect(f).to be_an(Admin::TranslatedRecordForm)
      end
    end
  end
end
