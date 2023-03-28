require 'spec_helper'

RSpec.describe AttachmentMasksController, type: :controller do
  let(:attachment) { FactoryBot.build(:body_text, id: 1) }
  let(:referer) { '/referer' }

  before do
    allow(GlobalID::Locator).to receive(:locate_signed).with('ABC').
      and_return(attachment)
  end

  describe 'GET wait' do
    def wait
      get :wait, params: { id: 'ABC', referer: referer }
    end

    context 'when attachment is masked' do
      it 'redirects to referer' do
        wait
        expect(response).to redirect_to('/referer')
      end
    end

    context 'when attachment is unmasked' do
      let(:attachment) { FactoryBot.build(:body_text, :unmasked, id: 1) }

      it 'queues FoiAttachmentMaskJob' do
        expect(FoiAttachmentMaskJob).to receive(:perform_later).
          with(attachment)
        wait
      end

      it 'renders wait template' do
        wait
        expect(response).to render_template(:wait)
      end

      it 'sets noindex header' do
        wait
        expect(response.headers['X-Robots-Tag']).to eq 'noindex'
      end
    end

    context 'without attachment' do
      let(:attachment) { nil }

      it 'raises record not found error' do
        expect { wait }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'without referer' do
      let(:referer) { '' }

      it 'raises route not found error' do
        expect { wait }.to raise_error(ApplicationController::RouteNotFound)
      end
    end
  end
end
