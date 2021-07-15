require 'spec_helper'

RSpec.describe "admin_user/show.html.erb" do

  before do
    info_requests = []
    allow(info_requests).to receive(:total_pages).and_return(0)
    assign :info_requests, info_requests
    assign :admin_user, user_being_viewed
    assign :comments, []
  end

  context 'when the current user cannot login as the user being viewed' do
    let(:current_user) { FactoryBot.create(:admin_user) }
    let(:user_being_viewed) { FactoryBot.create(:pro_user) }

    it 'should not show the list of post redirects' do
      with_feature_enabled(:alaveteli_pro) do
        allow(controller).to receive(:current_user).and_return(current_user)
        render :template => 'admin_user/show', :locals => { :current_user => current_user }
        expect(rendered).not_to match('Post redirects')
      end
    end

  end

  context 'when the current user can login as the user being viewed' do
    let(:current_user) { FactoryBot.create(:pro_admin_user) }
    let(:user_being_viewed) { FactoryBot.create(:pro_user) }

    it 'should show the list of post redirects' do
      with_feature_enabled(:alaveteli_pro) do
        allow(controller).to receive(:current_user).and_return(current_user)
        render :template => 'admin_user/show', :locals => { :current_user => current_user }
        expect(rendered).to match('Post redirects')
      end
    end

  end

end
