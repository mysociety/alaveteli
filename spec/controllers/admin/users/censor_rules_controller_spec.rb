require 'spec_helper'

RSpec.describe Admin::Users::CensorRulesController do
  describe 'GET #index' do
    let(:admin_user) { FactoryBot.create(:admin_user) }
    let(:pro_admin_user) { FactoryBot.create(:pro_admin_user) }

    let(:info_request) { FactoryBot.create(:info_request) }
    let(:user) { info_request.user }

    let!(:user_rule) { FactoryBot.create(:censor_rule, censorable: user) }
    let!(:request_rule) do
      FactoryBot.create(:censor_rule, censorable: info_request)
    end
    let!(:other_rule) { FactoryBot.create(:info_request_censor_rule) }

    render_views

    def index
      get :index, params: { user_id: user.id }
    end

    before { sign_in admin_user }

    it 'returns a successful response' do
      index
      expect(response).to be_successful
    end

    it 'renders the index template' do
      index
      expect(response).to render_template('index')
    end

    it 'assigns the user' do
      index
      expect(assigns[:admin_user]).to eq(user)
    end

    it 'assigns a page title' do
      index
      expect(assigns[:title]).to eq("Censor rules for #{user.name}")
    end

    it 'assigns the rules applying to the user’s requests' do
      index
      expect(assigns[:censor_rules]).to contain_exactly(user_rule, request_rule)
    end

    context 'when the user has no requests' do
      let(:user) { user_rule.censorable }
      let!(:user_rule) { FactoryBot.create(:user_censor_rule) }

      it 'assigns the rules attached to the user' do
        index
        expect(assigns[:censor_rules]).to contain_exactly(user_rule)
      end
    end

    context 'when a request is embargoed' do
      before { info_request.create_embargo }

      it 'excludes rules attached to embargoed requests' do
        with_feature_enabled(:alaveteli_pro) do
          index
          expect(assigns[:censor_rules]).not_to include(request_rule)
        end
      end

      context 'when the current user is a pro admin' do
        before { sign_in pro_admin_user }

        it 'includes rules attached to embargoed requests' do
          with_feature_enabled(:alaveteli_pro) do
            index
            expect(assigns[:censor_rules]).to include(request_rule)
          end
        end
      end
    end

    context 'with redaction tracking', feature: :redaction_tracking do
      let(:outgoing_message) { info_request.outgoing_messages.first }

      let!(:redaction) do
        request_rule.redactions.create!(
          redactable: outgoing_message, redacted_attribute: 'body'
        )
      end

      let!(:other_redaction) do
        other_rule.redactions.create!(
          redactable: other_rule.censorable.outgoing_messages.first,
          redacted_attribute: 'body'
        )
      end

      it 'assigns the redactions within the requests, grouped by rule' do
        index
        expect(assigns[:redactions]).to eq(request_rule.id => [redaction])
      end

      it 'lists each redacted record under its rule' do
        index
        expect(response.body).
          to include(edit_admin_outgoing_message_path(outgoing_message))
      end
    end

    context 'without redaction tracking' do
      it 'assigns no redactions' do
        index
        expect(assigns[:redactions]).to eq({})
      end
    end
  end

  describe 'POST #make_permanent' do
    let(:admin_user) { FactoryBot.create(:admin_user) }
    let(:info_request) { FactoryBot.create(:info_request) }
    let(:user) { info_request.user }

    let!(:user_rule) { FactoryBot.create(:censor_rule, censorable: user) }
    let!(:global_rule) { FactoryBot.create(:global_censor_rule) }

    before { sign_in admin_user }

    def make_permanent(ids)
      post :make_permanent,
           params: { user_id: user.id, censor_rule_ids: ids }
    end

    it 'erases the selected rules' do
      make_permanent([user_rule.id])
      expect(user_rule.reload).to be_erased
    end

    it 'does not erase rules that affect other users' do
      make_permanent([global_rule.id])
      expect(global_rule.reload).not_to be_erased
    end

    it 'redirects to the index' do
      make_permanent([user_rule.id])
      expect(response).to redirect_to(admin_user_censor_rules_path(user))
    end

    it 'sets an error when no rules are selected' do
      make_permanent([])
      expect(flash[:error]).to eq('No censor rules selected.')
    end
  end
end
