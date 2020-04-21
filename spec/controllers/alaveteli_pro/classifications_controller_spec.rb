require 'spec_helper'

RSpec.describe AlaveteliPro::ClassificationsController, type: :controller do
  describe '#create' do
    let(:pro_user) { FactoryBot.create(:pro_user) }
    let(:other_pro_user) { FactoryBot.create(:pro_user) }
    let(:info_request) { FactoryBot.create(:info_request, user: pro_user) }

    context 'when the user is not allowed to update the request' do
      it 'raises a CanCan::AccessDenied error' do
        session[:user_id] = other_pro_user.id
        expect do
          post :create, params: {
            url_title: info_request.url_title,
            info_request: { described_state: 'successful' }
          }
        end.to raise_error(CanCan::AccessDenied)
      end
    end
  end
end
