require 'spec_helper'

RSpec.describe RefusalAdviceController do
  describe 'POST #create' do
    let(:info_request) { FactoryBot.create(:info_request) }
    let(:user) { info_request.user }

    let(:params) do
      {
        url_title: info_request.url_title,
        refusal_advice: {
          questions: {
            exemption: 'section-12', question_1: 'no', question_2: 'yes'
          },
          actions: {
            action_1: { suggestion_1: 'false', suggestion_2: 'true' },
            action_2: { suggestion_3: 'true', suggestion_4: 'false' },
            action_3: { suggestion_5: 'false' }
          },
          id: 'action_2'
        }
      }
    end

    before do
      allow(controller).to receive(:current_user).and_return(user)
    end

    context 'when logged in as request owner' do
      before { session[:user_id] = user&.id }

      context 'valid params' do
        before do
          allow(InfoRequest).to receive(:find_by!).and_return(info_request)
        end

        it 'finds info request' do
          expect(InfoRequest).to receive(:find_by!).with(
            url_title: info_request.url_title
          )

          post :create, params: params
        end

        it 'logs event with correctly parsed params' do
          expect(info_request).to receive(:log_event).with(
            'refusal_advice',
            user_id: user.id,
            questions: {
              exemption: 'section-12', question_1: 'no', question_2: 'yes'
            },
            actions: {
              action_1: { suggestion_1: false, suggestion_2: true },
              action_2: { suggestion_3: true, suggestion_4: false },
              action_3: { suggestion_5: false }
            },
            id: 'action_2'
          )

          post :create, params: params
        end
      end

      context 'invalid refusal advice params' do
        before { params.deep_merge!(refusal_advice: { invalid: true }) }

        it 'raises error' do
          expect { post :create, params: params }.to raise_error(
            ActionController::UnpermittedParameters
          )
        end
      end

      context 'invalid url title param' do
        before { params.deep_merge!(url_title: 'invalid') }

        it 'cannot find info request' do
          expect { post :create, params: params }.to raise_error(
            ActiveRecord::RecordNotFound
          )
        end
      end

      context 'without refusal advice params' do
        before { params.delete(:refusal_advice) }

        it 'raises error' do
          expect { post :create, params: params }.to raise_error(
            ActionController::ParameterMissing
          )
        end
      end

      context 'without url title param' do
        before { params.delete(:url_title) }

        it 'returns no content' do
          post :create, params: params
          expect(response).to have_http_status(:no_content)
        end
      end
    end

    context 'when logged in as non-request owner' do
      let(:user) { FactoryBot.create(:user) }
      before { session[:user_id] = user&.id }

      it 'renders wrong user template' do
        post :create, params: params
        expect(response).to render_template('user/wrong_user')
      end

      context 'without url title param' do
        before { params.delete(:url_title) }

        it 'returns no content' do
          post :create, params: params
          expect(response).to have_http_status(:no_content)
        end
      end
    end

    context 'when logged out' do
      let(:user) { nil }

      it 'redirects to sign in form' do
        post :create, params: params
        expect(response).to be_redirect
      end

      it 'saves post redirect' do
        post :create, params: params
        expect(get_last_post_redirect&.uri).to eq '/refusal_advice'
      end

      context 'without url title param' do
        before { params.delete(:url_title) }

        it 'returns no content' do
          post :create, params: params
          expect(response).to have_http_status(:no_content)
        end
      end
    end
  end
end
