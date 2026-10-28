require 'spec_helper'

RSpec.describe 'request/similar' do
  let(:similar_requests) { FactoryBot.build_list(:info_request, 10) }

  let(:stub_locals) do
    { similar_requests: similar_requests }
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
end
