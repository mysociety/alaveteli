require 'spec_helper'

describe AnnouncementsController do

  describe '#destroy' do
    context 'not logged in' do
      before { session[:user_id] = nil }

      it 'returns 403 status' do
        delete :destroy, id: 1
        expect(response.status).to eq 403
      end

    end

    context 'logged in' do
      let(:user) { FactoryGirl.create(:user) }
      before { session[:user_id] = user.id }

      context 'valid announcement' do
        let(:announcement) { FactoryGirl.create(:announcement) }

        it 'creates dismissal' do
          expect { delete :destroy, id: announcement.id }.to change(
            AnnouncementDismissal, :count).by(1)
        end

        it 'returns 200 status' do
          delete :destroy, id: announcement.id
          expect(response.status).to eq 200
        end

      end

      context 'invalid announcement' do

        it 'returns 403 status' do
          delete :destroy, id: 'invalid'
          expect(response.status).to eq 403
        end

      end
    end

  end

end
