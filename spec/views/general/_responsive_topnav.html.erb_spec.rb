# -*- encoding : utf-8 -*-
require 'spec_helper'

describe 'general/_responsive_topnav.html.erb' do
  let(:user) { FactoryGirl.create(:user) }
  let(:pro_user) { FactoryGirl.create(:pro_user) }

  def render_view
    render :partial => 'general/responsive_topnav'
  end

  describe 'showing the Dashboard link', feature: :alaveteli_pro do

    context 'when a pro user is logged in' do
      before do
        assign :user, pro_user
      end

      it 'shows a Dashboard link' do
        render_view
        expect(rendered).to have_link('Dashboard')
      end

    end

    context 'when a normal user is logged in' do
      before do
        assign :user, user
      end

      it 'does not show a Dashboard link' do
        render_view
        expect(rendered).to_not have_link('Dashboard')
      end

    end

  end

end
