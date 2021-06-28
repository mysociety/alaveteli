require 'spec_helper'

RSpec.describe 'request/similar' do
  let(:info_request) { FactoryBot.build(:info_request) }
  let(:similar_requests) { FactoryBot.build_list(:info_request, 10) }
  let(:similar_more) { false }

  let(:stub_locals) do
    { info_request: info_request,
      similar_requests: similar_requests,
      similar_more: similar_more }
  end

  def render_view
    render partial: self.class.top_level_description,
           locals: stub_locals
  end

  it 'renders each request' do
    render_view
    expect(rendered).
      to render_template(partial: 'request/_request_listing_single_short')
  end

  context 'when there are no more similar requests' do
    it 'does not render link to the extra requests' do
      render_view
      expect(rendered).not_to match(/More similar requests/)
    end
  end

  context 'when there are more similar requests' do
    let(:similar_more) { [1, 2, 3] }

    it 'renders a link to the extra requests' do
      render_view
      expect(rendered).to match(/More similar requests/)
    end
  end
end
