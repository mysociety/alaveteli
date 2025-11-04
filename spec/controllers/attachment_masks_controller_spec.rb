require 'spec_helper'

RSpec.describe AttachmentMasksController, type: :controller do
  let(:attachment) { FactoryBot.build(:body_text, id: 1) }
  let(:referer) { 'DEF' }

  before do
    allow(GlobalID::Locator).to receive(:locate_signed).with('ABC').
      and_return(attachment)

    verifier = double('ActiveSupport::MessageVerifier')
    allow(controller).to receive(:verifier).and_return(verifier)
    allow(verifier).to receive(:generate).with('/referer').and_return('DEF')
    allow(verifier).to receive(:verified).and_return(nil)
    allow(verifier).to receive(:verified).with('DEF').and_return('/referer')
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
          done_attachment_mask_path('ABC', referer: 'DEF')
        )
      end
    end

    context 'when attachment is masked and referred from show as HTML action' do
      it 'redirects to referer' do
        allow(controller).to receive(:referred_from_show_as_html?).
          and_return(true)
        allow(attachment).to receive(:to_signed_global_id).and_return('ABC')
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

    context "when attachment can't be found" do
      it 'redirects to referer' do
        allow(GlobalID::Locator).to receive(:locate_signed).with('ABC').
          and_raise(ActiveRecord::RecordNotFound)
        wait
        expect(response).to redirect_to('/referer')
      end
    end

    context 'without attachment' do
      let(:attachment) { nil }

      it 'redirects to referer' do
        wait
        expect(response).to redirect_to('/referer')
      end
    end

    context 'without referer' do
      let(:referer) { '' }

      it 'raises route not found error' do
        expect { wait }.to raise_error(ApplicationController::RouteNotFound)
      end
    end

    context 'with modified referer' do
      let(:referer) { 'http://example.com/attack' }

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
          wait_for_attachment_mask_path('ABC', referer: 'DEF')
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

    context "when attachment can't be found" do
      it 'redirects to referer' do
        allow(GlobalID::Locator).to receive(:locate_signed).with('ABC').
          and_raise(ActiveRecord::RecordNotFound)
        done
        expect(response).to redirect_to('/referer')
      end
    end

    context 'without attachment' do
      let(:attachment) { nil }

      it 'redirects to referer' do
        done
        expect(response).to redirect_to('/referer')
      end
    end

    context 'without referer' do
      let(:referer) { '' }

      it 'raises route not found error' do
        expect { done }.to raise_error(ApplicationController::RouteNotFound)
      end
    end

    context 'with modified referer' do
      let(:referer) { 'http://example.com/attack' }

      it 'raises route not found error' do
        expect { done }.to raise_error(ApplicationController::RouteNotFound)
      end
    end
  end
end
