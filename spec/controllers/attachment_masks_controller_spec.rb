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
      it 'redirects to done action' do
        allow(attachment).to receive(:to_signed_global_id).and_return('ABC')
        wait
        expect(response).to redirect_to(
          done_attachment_mask_path('ABC', referer: '/referer')
        )
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

  describe 'GET done' do
    def done
      get :done, params: { id: 'ABC', referer: referer }
    end

    context 'when attachment is unmasked' do
      let(:attachment) { FactoryBot.build(:body_text, :unmasked, id: 1) }

      it 'redirects to wait action' do
        allow(attachment).to receive(:to_signed_global_id).and_return('ABC')
        done
        expect(response).to redirect_to(
          wait_for_attachment_mask_path('ABC', referer: '/referer')
        )
      end
    end

    context 'when attachment is masked' do
      it 'renders done template' do
        done
        expect(response).to render_template(:done)
      end

      it 'sets noindex header' do
        done
        expect(response.headers['X-Robots-Tag']).to eq 'noindex'
      end
    end

    context 'without attachment' do
      let(:attachment) { nil }

      it 'raises record not found error' do
        expect { done }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'without referer' do
      let(:referer) { '' }

      it 'raises route not found error' do
        expect { done }.to raise_error(ApplicationController::RouteNotFound)
      end
    end
  end
end
