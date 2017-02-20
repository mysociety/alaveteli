# -*- encoding : utf-8 -*-
require 'spec_helper'

describe 'general/_log_in_bar.html.erb' do
  let(:user) { FactoryGirl.create(:user) }
  let(:pro_user) { FactoryGirl.create(:pro_user) }

  def render_view
    render :partial => 'general/log_in_bar'
  end

  describe 'sign out link' do
    before do
      # The view uses request.fullpath to set return links
      allow(view.request).to receive(:fullpath).and_return('/test/fullpath')
    end

    context 'when a pro user is logged in' do
      before do
        assign :user, pro_user
      end

      context 'and the page is in the pro area' do
        before do
          assign :in_pro_area, true
        end

        it 'does not set a return path' do
          render_view
          expect(rendered).to have_link("Sign out", href: signout_path)
        end
      end

      context 'and the page is not in the pro area' do
        before do
          assign :in_pro_area, false
        end

        it 'sets the return path to the current page' do
          render_view
          expect(rendered).to have_link("Sign out", href: signout_path(r: '/test/fullpath'))
        end
      end
    end

    context 'when a normal user is logged in' do
      before do
        assign :user, user
      end

      it 'sets the return path to the current page' do
        render_view
        expect(rendered).to have_link("Sign out", href: signout_path(r: '/test/fullpath'))
      end
    end
  end
end
