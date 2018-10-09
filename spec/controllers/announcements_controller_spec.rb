require 'spec_helper'

describe AnnouncementsController do

  describe '#destroy' do

    context 'valid announcement' do
      let(:announcement) { FactoryBot.create(:announcement) }

      context 'logged in' do
        let(:user) { FactoryBot.create(:user) }
        before { session[:user_id] = user.id }

        it 'creates dismissal' do
          expect { delete :destroy, id: announcement.id }.to change(
            AnnouncementDismissal, :count).by(1)

        end

        it 'returns 200 status' do
          delete :destroy, id: announcement.id
          expect(response.status).to eq 200
        end

      end

      context 'logged out' do

        it 'stores announcement ID in session' do
          expect(session[:announcement_dismissals]).to be_nil
          delete :destroy, id: announcement.id
          expect(session[:announcement_dismissals]).
            to match_array([announcement.id])
        end

        it 'returns 200 status' do
          delete :destroy, id: announcement.id
          expect(response.status).to eq 200
        end

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
