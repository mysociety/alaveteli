require 'spec_helper'

describe "admin_request/show.html.erb" do

  before do
    assign :info_request, info_request
  end

  context 'for a public request' do
    let(:info_request) { FactoryBot.create(:info_request) }

    it 'links to the public request page' do
      render
      expect(rendered).to match(request_url(info_request))
    end

    it 'does not include embargoed label' do
      render
      expect(rendered).to_not have_css('h1 span.label', text: 'embargoed')
    end

  end

  context 'for an embargoed request' do
    let(:info_request) { FactoryBot.create(:embargoed_request) }

    it 'links to the pro request page' do
      render
      expect(rendered).to match(show_alaveteli_pro_request_url(info_request.url_title))
    end

    it 'includes embargo information' do
      render
      expect(rendered).to match('Private until')
    end

    it 'includes embargoed label' do
      render
      expect(rendered).to have_css('h1 span.label', text: 'embargoed')
    end

  end

  context 'for a redacted request' do

    let(:info_request) do
      request = FactoryBot.create(:info_request)
      FactoryBot.create(:info_request_censor_rule,
                        text: 'information',
                        replacement: '[REDACTED]',
                        info_request: request)
      request.reload
    end

    it 'shows the redacted message in the main Outgoing Messages section' do
      render
      expect(rendered).to have_css('#outgoing_messages blockquote',
                                   text: 'Some [REDACTED] please')
    end

    it 'shows the unredacted message in the Outgoing Messages accordion' do
      render
      ogm = info_request.outgoing_messages.last
      expect(rendered).to have_css("#outgoing_#{ogm.id}",
                                   text: 'Some information please')
    end

  end

end
