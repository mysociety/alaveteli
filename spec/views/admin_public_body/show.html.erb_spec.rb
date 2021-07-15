require 'spec_helper'

describe "admin_public_body/show.html.erb" do
  let(:public_body) { FactoryBot.create(:public_body) }


  before do
    info_requests = []
    allow(info_requests).to receive(:total_pages).and_return(0)
    assign :public_body, public_body
    assign :info_requests, info_requests
    assign :versions, []
  end

  context 'when the user cannot view API keys ' do
    let(:current_user) { FactoryBot.create(:admin_user) }

    it 'does not display the API key' do
      with_feature_enabled(:alaveteli_pro) do
        allow(controller).to receive(:current_user).and_return(current_user)
        render :template => 'admin_public_body/show', :locals => { :current_user => current_user }
        expect(rendered).not_to match(Regexp.escape(public_body.api_key))
      end
    end

  end

  context 'when the user can view API keys' do
    let(:current_user) { FactoryBot.create(:pro_admin_user) }

    it 'displays the API key' do
      with_feature_enabled(:alaveteli_pro) do
        allow(controller).to receive(:current_user).and_return(current_user)
        render :template => 'admin_public_body/show', :locals => { :current_user => current_user }
        expect(rendered).to match(Regexp.escape(public_body.api_key))
      end
    end

  end

end
