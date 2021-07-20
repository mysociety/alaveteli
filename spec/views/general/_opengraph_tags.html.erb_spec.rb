require 'spec_helper'

RSpec.describe 'general/_opengraph_tags.html.erb' do

  def render_view
    render :partial => 'general/opengraph_tags'
  end

  describe 'displaying the opengraph logo', feature: :alaveteli_pro do
    before do
      assign(:in_pro_area, true)
    end

    it 'shows pro version of the logo if it is available' do
      allow(view).to receive(:theme_asset_exists?).
        with('images/logo-opengraph-pro.png').and_return true
      render_view
      expect(rendered).
        to match('content="http://test.host/assets/logo-opengraph-pro')
    end

    it 'shows standard version of the logo if the pro version is not found' do
      allow(view).to receive(:theme_asset_exists?).
        with('images/logo-opengraph-pro.png').and_return false
      render_view
      expect(rendered).
        to_not match('content="http://test.host/assets/logo-opengraph-pro')
    end

  end

end
