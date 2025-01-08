require 'spec_helper'
require 'integration/alaveteli_dsl'

RSpec.describe 'showing admin tags' do
  around do |example|
    using_session(login(:admin_user)) do
      example.run
    end
  end

  context 'when tags contain colons or slashes' do
    let!(:public_body) do
      FactoryBot.create(:public_body, tag_string: 'http://foo.bar')
    end

    let!(:info_request) do
      FactoryBot.create(:info_request, tag_string: 'url:http://foo.bar')
    end

    it 'loads taggings correctly' do
      public_body_path = admin_public_body_path(public_body)
      info_request_path = admin_info_request_path(info_request)

      visit 'admin/tags/http?model_type=PublicBody'
      expect(page.has_link?(href: public_body_path)).to eq true
      expect(page.has_link?(href: info_request_path)).to eq false

      visit 'admin/tags/http:%2F%2Ffoo.bar?model_type=PublicBody'
      expect(page.has_link?(href: public_body_path)).to eq true
      expect(page.has_link?(href: info_request_path)).to eq false

      visit 'admin/tags/url?model_type=InfoRequest'
      expect(page.has_link?(href: public_body_path)).to eq false
      expect(page.has_link?(href: info_request_path)).to eq true

      visit 'admin/tags/url:http:%2F%2Ffoo.bar?model_type=InfoRequest'
      expect(page.has_link?(href: public_body_path)).to eq false
      expect(page.has_link?(href: info_request_path)).to eq true
    end
  end
end
