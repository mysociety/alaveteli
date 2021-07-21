require 'spec_helper'

RSpec.describe 'when displaying user listings' do
  let(:highlighted_words) { [] }
  let(:user) { FactoryBot.create(:user) }

  before do
    assign :highlight_words, highlighted_words
  end

  def render_view
    render :partial => 'user/user_listing_single',
           :locals => { :display_user => user }
  end

  it 'displays a normal request' do
    FactoryBot.create(:info_request, :user => user)
    render_view
    expect(rendered).to have_text '1 request made'
  end

  it 'does not display an embargoed request' do
    FactoryBot.create(:embargoed_request, :user => user)
    render_view
    expect(rendered).to have_text '0 requests made'
  end

  it 'does not display a hidden request' do
    FactoryBot.create(:hidden_request, :user => user)
    render_view
    expect(rendered).to have_text '0 requests made'
  end
end
