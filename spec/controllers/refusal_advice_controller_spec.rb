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

    let(:target) { { internal: 'followup' } }
    let(:action) { RefusalAdvice::Action.new(id: 'action_2', target: target) }

    before do
      allow(controller).to receive(:current_user).and_return(user)
      allow(RefusalAdvice).to receive(:default).
        and_return(double(actions: [action]))
    end

    shared_examples 'internal target redirection' do
      context 'when internal followup target' do
        let(:target) { { internal: 'followup' } }

        it 'redirects to new followup action' do
          post :create, params: params
          expect(response).to redirect_to(
            new_request_followup_path(
              request_id: info_request.id,
              anchor: 'followup'
            )
          )
        end
      end

      context 'when internal followup target' do
        let(:target) { { internal: 'internal_review' } }

        it 'redirects to new internal review action' do
          post :create, params: params
          expect(response).to redirect_to(
            new_request_followup_path(
              request_id: info_request.id,
              internal_review: '1',
              anchor: 'followup'
            )
          )
        end
      end

      context 'when new request target' do
        let(:target) { { internal: 'new_request' } }

        it 'redirects to new request action' do
          post :create, params: params
          expect(response).to redirect_to(
            new_request_to_body_path(
              url_name: info_request.public_body.url_name
            )
          )
        end
      end

      context 'when unknown internal target' do
        let(:target) { { internal: 'unknown' } }

        it 'raises redirection error' do
          expect { post :create, params: params }.to raise_error(
            RefusalAdvice::Action::RedirectionError,
            %q(Can't redirect to {:internal=>"unknown"})
          )
        end
      end
    end

    shared_examples 'internal target exception' do
      context 'when internal followup target' do
        let(:target) { { internal: 'followup' } }

        it 'raises redirection error' do
          expect { post :create, params: params }.to raise_error(
            RefusalAdvice::Action::RedirectionError,
            %q(Can't redirect to {:internal=>"followup"})
          )
        end
      end

      context 'when internal followup target' do
        let(:target) { { internal: 'internal_review' } }

        it 'raises redirection error' do
          expect { post :create, params: params }.to raise_error(
            RefusalAdvice::Action::RedirectionError,
            %q(Can't redirect to {:internal=>"internal_review"})
          )
        end
      end

      context 'when new request target' do
        let(:target) { { internal: 'new_request' } }

        it 'raises redirection error' do
          expect { post :create, params: params }.to raise_error(
            RefusalAdvice::Action::RedirectionError,
            %q(Can't redirect to {:internal=>"new_request"})
          )
        end
      end

      context 'when unknown internal target' do
        let(:target) { { internal: 'unknown' } }

        it 'raises redirection error' do
          expect { post :create, params: params }.to raise_error(
            RefusalAdvice::Action::RedirectionError,
            %q(Can't redirect to {:internal=>"unknown"})
          )
        end
      end
    end

    shared_examples 'help page target redirection' do
      context 'when help page target' do
        let(:target) { { help_page: 'ico' } }

        it 'redirects to help page' do
          post :create, params: params
          expect(response).to redirect_to(help_general_path(template: 'ico'))
        end
      end
    end

    shared_examples 'external target redirection' do
      context 'when external target' do
        let(:target) { { external: 'http://www.writetothem.com/' } }

        it 'redirects to external page' do
          post :create, params: params
          expect(response).to redirect_to('http://www.writetothem.com/')
        end
      end
    end

    shared_examples 'invalid target exception' do
      context 'when invalid target' do
        let(:target) { { invalid: 'invalid' } }

        it 'raises redirection error' do
          expect { post :create, params: params }.to raise_error(
            RefusalAdvice::Action::RedirectionError,
            %q(Can't redirect to {:invalid=>"invalid"})
          )
        end
      end
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

        include_examples 'internal target redirection'
        include_examples 'help page target redirection'
        include_examples 'external target redirection'
        include_examples 'invalid target exception'
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

        include_examples 'internal target exception'
        include_examples 'help page target redirection'
        include_examples 'external target redirection'
        include_examples 'invalid target exception'
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

        include_examples 'internal target exception'
        include_examples 'help page target redirection'
        include_examples 'external target redirection'
        include_examples 'invalid target exception'
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

        include_examples 'internal target exception'
        include_examples 'help page target redirection'
        include_examples 'external target redirection'
        include_examples 'invalid target exception'
      end
    end
  end
end
