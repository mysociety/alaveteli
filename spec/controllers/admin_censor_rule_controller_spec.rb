require 'spec_helper'

RSpec.describe AdminCensorRuleController do
  before(:each) { basic_auth_login(@request) }

  describe 'GET index' do

    let!(:global_rules) do
      3.times.map { FactoryBot.create(:global_censor_rule) }
    end

    before do
      get :index
    end

    it 'returns a successful response' do
      expect(response).to be_successful
    end

    it 'collects admin censor rules' do
      FactoryBot.create(:info_request_censor_rule)
      FactoryBot.create(:public_body_censor_rule)
      FactoryBot.create(:user_censor_rule)
      expect(assigns[:censor_rules]).to match_array(global_rules)
    end

    it 'renders the correct template' do
      expect(response).to render_template('index')
    end

  end

  describe 'GET new' do

    context 'global censor rule' do

      before do
        get :new
      end

      it 'returns a successful response' do
        expect(response).to be_successful
      end

      it 'initializes a new censor rule' do
        expect(assigns[:censor_rule]).to be_new_record
      end

      it 'renders the correct template' do
        expect(response).to render_template('new')
      end

      it 'does not associate the censor rule with an info request' do
        expect(assigns[:censor_rule].info_request).to be_nil
      end

      it 'does not associate the censor rule with a public body' do
        expect(assigns[:censor_rule].public_body).to be_nil
      end

      it 'does not associate the censor rule with a user' do
        expect(assigns[:censor_rule].user).to be_nil
      end

      it 'sets the URL for the form to POST to' do
        expect(assigns[:form_url]).to eq(admin_censor_rules_path)
      end

    end

    context 'request_id param' do

      let(:info_request) { FactoryBot.create(:info_request) }

      before do
        get :new, params: { :request_id => info_request.id }
      end

      it 'returns a successful response' do
        expect(response).to be_successful
      end

      it 'initializes a new censor rule' do
        expect(assigns[:censor_rule]).to be_new_record
      end

      it 'renders the correct template' do
        expect(response).to render_template('new')
      end

      it 'finds an info request if the request_id param is supplied' do
        expect(assigns[:info_request]).to eq(info_request)
      end

      it 'associates the info request with the new censor rule' do
        expect(assigns[:censor_rule].info_request).to eq(info_request)
      end

      it 'sets the URL for the form to POST to' do
        expect(assigns[:form_url]).
          to eq(admin_request_censor_rules_path(info_request))
      end

    end

    context 'user_id param' do

      let(:user) { FactoryBot.create(:user) }

      before do
        get :new, params: { :user_id => user.id }
      end

      it 'returns a successful response' do
        expect(response).to be_successful
      end

      it 'initializes a new censor rule' do
        expect(assigns[:censor_rule]).to be_new_record
      end

      it 'renders the correct template' do
        expect(response).to render_template('new')
      end

      it 'finds a user if the user_id param is supplied' do
        expect(assigns[:censor_user]).to eq(user)
      end

      it 'associates the user with the new censor rule' do
        expect(assigns[:censor_rule].user).to eq(user)
      end

      it 'sets the URL for the form to POST to' do
        expect(assigns[:form_url]).to eq(admin_user_censor_rules_path(user))
      end

    end

    # NOTE: This should be public_body_id but the resource is mapped as :bodies
    context 'body_id param' do

      let(:public_body) { FactoryBot.create(:public_body) }

      before do
        get :new, params: { :body_id => public_body.id }
      end

      it 'returns a successful response' do
        expect(response).to be_successful
      end

      it 'initializes a new censor rule' do
        expect(assigns[:censor_rule]).to be_new_record
      end

      it 'renders the correct template' do
        expect(response).to render_template('new')
      end

      it 'finds a public body if the public_body_id param is supplied' do
        expect(assigns[:public_body]).to eq(public_body)
      end

      it 'associates the public_body with the new censor rule' do
        expect(assigns[:censor_rule].public_body).to eq(public_body)
      end

      it 'sets the URL for the form to POST to' do
        expect(assigns[:form_url]).
          to eq(admin_body_censor_rules_path(public_body))
      end

    end

  end

  describe 'POST create' do

    context 'a global censor rule' do

      let(:censor_rule_params) do
        params = FactoryBot.attributes_for(:global_censor_rule)
        # last_edit_editor gets set in the controller
        params.delete(:last_edit_editor)
        params
      end

      def create_censor_rule
        post :create, params: { :censor_rule => censor_rule_params }
      end

      it 'sets the last_edit_editor to the current admin' do
        create_censor_rule
        expect(assigns[:censor_rule].last_edit_editor).to eq('*unknown*')
      end

      it 'does not associate the censor rule with an info request' do
        create_censor_rule
        expect(assigns[:censor_rule].info_request).to be_nil
      end

      it 'does not associate the censor rule with a public body' do
        create_censor_rule
        expect(assigns[:censor_rule].public_body).to be_nil
      end

      it 'does not associate the censor rule with a user' do
        create_censor_rule
        expect(assigns[:censor_rule].user).to be_nil
      end

      it 'sets the URL for the form to POST to' do
        create_censor_rule
        expect(assigns[:form_url]).to eq(admin_censor_rules_path)
      end

      context 'successfully saving the censor rule' do

        it 'calls expire_requests on the new censor_rule' do
          censor_rule = FactoryBot.build(:global_censor_rule)
          allow(CensorRule).to receive(:new) { censor_rule }
          allow(censor_rule).to receive(:expire_requests)

          create_censor_rule

          expect(censor_rule).to have_received(:expire_requests)
        end

        it 'redirects to the censor rules index' do
          create_censor_rule
          expect(response).to redirect_to(
            admin_censor_rules_path
          )
        end

      end

      context 'unsuccessfully saving the censor rule' do

        before(:each) do
          allow_any_instance_of(CensorRule).to receive(:save).and_return(false)
        end

        it 'does not persist the censor rule' do
          create_censor_rule
          expect(assigns[:censor_rule]).to be_new_record
        end

        it 'renders the form' do
          create_censor_rule
          expect(response).to render_template('new')
        end

      end

    end

    context 'request_id param' do

      let(:censor_rule_params) do
        params = FactoryBot.attributes_for(:info_request_censor_rule)
        # last_edit_editor gets set in the controller
        params.delete(:last_edit_editor)
        params
      end

      let(:info_request) { FactoryBot.create(:info_request) }

      it 'sets the last_edit_editor to the current admin' do
        post :create, params: {
                        :request_id => info_request.id,
                        :censor_rule => censor_rule_params
                      }
        expect(assigns[:censor_rule].last_edit_editor).to eq('*unknown*')
      end

      it 'finds an info request if the request_id param is supplied' do
        post :create, params: {
                        :request_id => info_request.id,
                        :censor_rule => censor_rule_params
                      }
        expect(assigns[:info_request]).to eq(info_request)
      end

      it 'associates the info request with the new censor rule' do
        post :create, params: {
                        :request_id => info_request.id,
                        :censor_rule => censor_rule_params
                      }
        expect(assigns[:censor_rule].info_request).to eq(info_request)
      end

      it 'sets the URL for the form to POST to' do
        post :create, params: {
                        :request_id => info_request.id,
                        :censor_rule => censor_rule_params
                      }
        expect(assigns[:form_url]).
          to eq(admin_request_censor_rules_path(info_request))
      end

      context 'successfully saving the censor rule' do

        it 'persists the censor rule' do
          post :create, params: {
                          :censor_rule => censor_rule_params,
                          :request_id => info_request.id
                        }
          expect(assigns[:censor_rule]).to be_persisted
        end

        it 'confirms the censor rule is created' do
          post :create, params: {
                          :censor_rule => censor_rule_params,
                          :request_id => info_request.id
                        }
          msg = 'Censor rule was successfully created.'
          expect(flash[:notice]).to eq(msg)
        end

        it 'calls expire_requests on the new censor_rule' do
          allow(InfoRequest).to receive(:find).and_return(info_request)
          censor_rule_spy = FactoryBot.build(:info_request_censor_rule,
                                             :info_request => info_request)
          allow(info_request.censor_rules).to receive(:build).
            and_return(censor_rule_spy)

          allow(censor_rule_spy).to receive(:expire_requests)

          post :create, params: {
                          :censor_rule => censor_rule_params,
                          :request_id => info_request.id
                        }

          expect(censor_rule_spy).to have_received(:expire_requests)
        end

        it 'redirects to the associated info request' do
          post :create, params: {
                          :censor_rule => censor_rule_params,
                          :request_id => info_request.id
                        }
          expect(response).to redirect_to(
            admin_request_path(assigns[:censor_rule].info_request)
          )
        end
      end

      context 'unsuccessfully saving the censor rule' do

        before(:each) do
          allow_any_instance_of(CensorRule).to receive(:save).and_return(false)
        end

        it 'does not persist the censor rule' do
          post :create, params: {
                          :censor_rule => censor_rule_params,
                          :request_id => info_request.id
                        }
          expect(assigns[:censor_rule]).to be_new_record
        end

        it 'renders the form' do
          post :create, params: {
                          :censor_rule => censor_rule_params,
                          :request_id => info_request.id
                        }
          expect(response).to render_template('new')
        end

      end
    end

    context 'user_id param' do

      let(:user) { FactoryBot.create(:user) }

      let(:censor_rule_params) do
        params = FactoryBot.attributes_for(:user_censor_rule, :user => user)
        # last_edit_editor gets set in the controller
        params.delete(:last_edit_editor)
        params
      end

      def create_censor_rule
        post :create, params: {
                        :user_id => user.id,
                        :censor_rule => censor_rule_params
                      }
      end

      it 'sets the last_edit_editor to the current admin' do
        create_censor_rule
        expect(assigns[:censor_rule].last_edit_editor).to eq('*unknown*')
      end

      it 'finds a user if the user_id param is supplied' do
        create_censor_rule
        expect(assigns[:censor_user]).to eq(user)
      end

      it 'associates the user with the new censor rule' do
        create_censor_rule
        expect(assigns[:censor_rule].user).to eq(user)
      end

      it 'sets the URL for the form to POST to' do
        create_censor_rule
        expect(assigns[:form_url]).to eq(admin_user_censor_rules_path(user))
      end

      context 'successfully saving the censor rule' do

        it 'calls expire_requests on the new censor_rule' do
          allow(User).to receive(:find) { user }
          censor_rule = FactoryBot.build(:user_censor_rule,
                                         :user => user)
          allow(user.censor_rules).to receive(:build) { censor_rule }
          allow(censor_rule).to receive(:expire_requests)

          create_censor_rule

          expect(censor_rule).to have_received(:expire_requests)
        end

        it 'redirects to the associated info request' do
          create_censor_rule
          expect(response).to redirect_to(
            admin_user_path(assigns[:censor_rule].user)
          )
        end

      end

      context 'unsuccessfully saving the censor rule' do

        before(:each) do
          allow_any_instance_of(CensorRule).to receive(:save).and_return(false)
        end

        it 'does not persist the censor rule' do
          post :create, params: {
                          :censor_rule => censor_rule_params,
                          :user_id => user.id
                        }
          expect(assigns[:censor_rule]).to be_new_record
        end

        it 'renders the form' do
          post :create, params: {
                          :censor_rule => censor_rule_params,
                          :user_id => user.id
                        }
          expect(response).to render_template('new')
        end

      end

    end

    context 'body_id param' do

      let(:censor_rule_params) do
        params = FactoryBot.attributes_for(:public_body_censor_rule)
        # last_edit_editor gets set in the controller
        params.delete(:last_edit_editor)
        params
      end

      let(:public_body) { FactoryBot.create(:public_body) }

      before(:each) do
        post :create, params: {
                        :body_id => public_body.id,
                        :censor_rule => censor_rule_params
                      }
      end

      it 'sets the last_edit_editor to the current admin' do
        expect(assigns[:censor_rule].last_edit_editor).to eq('*unknown*')
      end

      it 'finds a public body if the body_id param is supplied' do
        expect(assigns[:public_body]).to eq(public_body)
      end

      it 'associates the public body with the new censor rule' do
        expect(assigns[:censor_rule].public_body).to eq(public_body)
      end

      it 'sets the URL for the form to POST to' do
        expect(assigns[:form_url]).
          to eq(admin_body_censor_rules_path(public_body))
      end

      context 'successfully saving the censor rule' do

        it 'persists the censor rule' do
          post :create, params: {
                          :censor_rule => censor_rule_params,
                          :body_id => public_body.id
                        }
          expect(assigns[:censor_rule]).to be_persisted
        end

        it 'confirms the censor rule is created' do
          post :create, params: {
                          :censor_rule => censor_rule_params,
                          :body_id => public_body.id
                        }
          msg = 'Censor rule was successfully created.'
          expect(flash[:notice]).to eq(msg)
        end

        it 'calls expire_requests on the new censor_rule' do
          allow(PublicBody).to receive(:find) { public_body }
          censor_rule = FactoryBot.build(:public_body_censor_rule,
                                         :public_body => public_body)
          allow(public_body.censor_rules).to receive(:build) { censor_rule }
          allow(censor_rule).to receive(:expire_requests)

          post :create, params: {
                          :censor_rule => censor_rule_params,
                          :body_id => public_body.id
                        }

          expect(censor_rule).to have_received(:expire_requests)
        end

        it 'redirects to the associated public body' do
          post :create, params: {
                          :censor_rule => censor_rule_params,
                          :body_id => public_body.id
                        }
          expect(response).to redirect_to(
            admin_body_path(assigns[:censor_rule].public_body)
          )
        end
      end

      context 'unsuccessfully saving the censor rule' do

        before(:each) do
          allow_any_instance_of(CensorRule).to receive(:save).and_return(false)
        end

        it 'does not persist the censor rule' do
          post :create, params: {
                          :censor_rule => censor_rule_params,
                          :body_id => public_body.id
                        }
          expect(assigns[:censor_rule]).to be_new_record
        end

        it 'renders the form' do
          post :create, params: {
                          :censor_rule => censor_rule_params,
                          :body_id => public_body.id
                        }
          expect(response).to render_template('new')
        end

      end
    end

  end

  describe 'GET edit' do

    context 'a CensorRule with an associated InfoRequest' do

      let(:censor_rule) { FactoryBot.create(:info_request_censor_rule) }

      it 'returns a successful response' do
        get :edit, params: { :id => censor_rule.id }
        expect(response).to be_successful
      end

      it 'renders the correct template' do
        get :edit, params: { :id => censor_rule.id }
        expect(response).to render_template('edit')
      end

      it 'finds the correct censor rule to edit' do
        get :edit, params: { :id => censor_rule.id }
        expect(assigns[:censor_rule]).to eq(censor_rule)
      end

    end

    context 'a CensorRule with an associated User' do

      let(:censor_rule) { FactoryBot.create(:user_censor_rule) }

      it 'returns a successful response' do
        get :edit, params: { :id => censor_rule.id }
        expect(response).to be_successful
      end

      it 'renders the correct template' do
        get :edit, params: { :id => censor_rule.id }
        expect(response).to render_template('edit')
      end

      it 'finds the correct censor rule to edit' do
        get :edit, params: { :id => censor_rule.id }
        expect(assigns[:censor_rule]).to eq(censor_rule)
      end

    end

    context 'a CensorRule with an associated PublicBody' do

      let(:censor_rule) { FactoryBot.create(:public_body_censor_rule) }

      it 'returns a successful response' do
        get :edit, params: { :id => censor_rule.id }
        expect(response).to be_successful
      end

      it 'renders the correct template' do
        get :edit, params: { :id => censor_rule.id }
        expect(response).to render_template('edit')
      end

      it 'finds the correct censor rule to edit' do
        get :edit, params: { :id => censor_rule.id }
        expect(assigns[:censor_rule]).to eq(censor_rule)
      end

    end

    context 'a global rule' do

      let(:censor_rule) { FactoryBot.create(:global_censor_rule) }

      it 'returns a successful response' do
        get :edit, params: { :id => censor_rule.id }
        expect(response).to be_successful
      end

      it 'renders the correct template' do
        get :edit, params: { :id => censor_rule.id }
        expect(response).to render_template('edit')
      end

      it 'finds the correct censor rule to edit' do
        get :edit, params: { :id => censor_rule.id }
        expect(assigns[:censor_rule]).to eq(censor_rule)
      end

    end

  end

  describe 'PUT update' do

    context 'a global censor rule' do

      let(:censor_rule) { FactoryBot.create(:global_censor_rule) }

      it 'finds the correct censor rule to edit' do
        put :update, params: {
                      :id => censor_rule.id,
                      :censor_rule => { :text => 'different text' }
                    }

        expect(assigns[:censor_rule]).to eq(censor_rule)
      end

      it 'sets the last_edit_editor to the current admin' do
        put :update, params: {
                       :id => censor_rule.id,
                       :censor_rule => { :text => 'different text' }
                     }

        expect(assigns[:censor_rule].last_edit_editor).to eq('*unknown*')
      end

      context 'successfully saving the censor rule' do

        it 'updates the censor rule' do
          put :update, params: {
                         :id => censor_rule.id,
                         :censor_rule => { :text => 'different text' }
                       }
          censor_rule.reload
          expect(censor_rule.text).to eq('different text')
        end

        it 'confirms the censor rule is updated' do
          put :update, params: {
                         :id => censor_rule.id,
                         :censor_rule => { :text => 'different text' }
                       }
          msg = 'Censor rule was successfully updated.'
          expect(flash[:notice]).to eq(msg)
        end

        it 'calls expire_requests on the censor_rule' do
          allow(CensorRule).to receive(:find) { censor_rule }
          allow(censor_rule).to receive(:expire_requests)
          put :update, params: {
                         :id => censor_rule.id,
                         :censor_rule => { :text => 'different text' }
                       }

          expect(censor_rule).to have_received(:expire_requests)
        end

        it 'redirects to the censor rule index' do
          put :update, params: {
                         :id => censor_rule.id,
                         :censor_rule => { :text => 'different text' }
                       }

          expect(response).to redirect_to(admin_censor_rules_path)
        end

      end

      context 'unsuccessfully saving the censor rule' do

        before(:each) do
          allow_any_instance_of(CensorRule).to receive(:save).and_return(false)
        end

        it 'does not update the censor rule' do
          put :update, params: {
                         :id => censor_rule.id,
                         :censor_rule => { :text => 'different text' }
                       }
          censor_rule.reload
          expect(censor_rule.text).to eq('some text to redact')
        end

        it 'renders the form' do
          put :update, params: {
                         :id => censor_rule.id,
                         :censor_rule => { :text => 'different text' }
                       }

          expect(response).to render_template('edit')
        end

      end

    end

    context 'a CensorRule with an associated InfoRequest' do

      let(:censor_rule) { FactoryBot.create(:info_request_censor_rule) }

      it 'finds the correct censor rule to edit' do
        put :update, params: {
                       :id => censor_rule.id,
                       :censor_rule => { :text => 'different text' }
                     }

        expect(assigns[:censor_rule]).to eq(censor_rule)
      end

      it 'sets the last_edit_editor to the current admin' do
        put :update, params: {
                       :id => censor_rule.id,
                       :censor_rule => { :text => 'different text' }
                     }

        expect(assigns[:censor_rule].last_edit_editor).to eq('*unknown*')
      end

      context 'successfully saving the censor rule' do

        it 'updates the censor rule' do
          put :update, params: {
                         :id => censor_rule.id,
                         :censor_rule => { :text => 'different text' }
                       }
          censor_rule.reload
          expect(censor_rule.text).to eq('different text')
        end

        it 'confirms the censor rule is updated' do
          put :update, params: {
                         :id => censor_rule.id,
                         :censor_rule => { :text => 'different text' }
                       }
          msg = 'Censor rule was successfully updated.'
          expect(flash[:notice]).to eq(msg)
        end

        it 'calls expire_requests on the censor_rule' do
          allow(CensorRule).to receive(:find) { censor_rule }
          allow(censor_rule).to receive(:expire_requests)
          put :update, params: {
                         :id => censor_rule.id,
                         :censor_rule => { :text => 'different text' }
                       }

          expect(censor_rule).to have_received(:expire_requests)
        end

        it 'redirects to the associated info request' do
          put :update, params: {
                         :id => censor_rule.id,
                         :censor_rule => { :text => 'different text' }
                       }

          expect(response).to redirect_to(
            admin_request_path(assigns[:censor_rule].info_request)
          )
        end

      end

      context 'unsuccessfully saving the censor rule' do

        before(:each) do
          allow_any_instance_of(CensorRule).to receive(:save).and_return(false)
        end

        it 'does not update the censor rule' do
          put :update, params: {
                         :id => censor_rule.id,
                         :censor_rule => { :text => 'different text' }
                       }
          censor_rule.reload
          expect(censor_rule.text).to eq('some text to redact')
        end

        it 'renders the form' do
          put :update, params: {
                         :id => censor_rule.id,
                         :censor_rule => { :text => 'different text' }
                       }

          expect(response).to render_template('edit')
        end

      end

    end

    context 'a CensorRule with an associated User' do

      let(:censor_rule) { FactoryBot.create(:user_censor_rule) }

      it 'finds the correct censor rule to edit' do
        put :update, params: {
                       :id => censor_rule.id,
                       :censor_rule => { :text => 'different text' }
                     }

        expect(assigns[:censor_rule]).to eq(censor_rule)
      end

      it 'sets the last_edit_editor to the current admin' do
        put :update, params: {
                       :id => censor_rule.id,
                       :censor_rule => { :text => 'different text' }
                     }

        expect(assigns[:censor_rule].last_edit_editor).to eq('*unknown*')
      end

      context 'successfully saving the censor rule' do
        it 'updates the censor rule' do
          put :update, params: {
                         :id => censor_rule.id,
                         :censor_rule => { :text => 'different text' }
                       }
          censor_rule.reload
          expect(censor_rule.text).to eq('different text')
        end

        it 'confirms the censor rule is updated' do
          put :update, params: {
                         :id => censor_rule.id,
                         :censor_rule => { :text => 'different text' }
                       }
          msg = 'Censor rule was successfully updated.'
          expect(flash[:notice]).to eq(msg)
        end

        it 'calls expire_requests on the censor_rule' do
          allow(CensorRule).to receive(:find) { censor_rule }
          allow(censor_rule).to receive(:expire_requests)
          put :update, params: {
                         :id => censor_rule.id,
                         :censor_rule => { :text => 'different text' }
                       }

          expect(censor_rule).to have_received(:expire_requests)
        end

        it 'redirects to the associated info request' do
          put :update, params: {
                         :id => censor_rule.id,
                         :censor_rule => { :text => 'different text' }
                       }

          expect(response).to redirect_to(
            admin_user_path(assigns[:censor_rule].user)
          )
        end
      end

      context 'unsuccessfully saving the censor rule' do

        before(:each) do
          allow_any_instance_of(CensorRule).to receive(:save).and_return(false)
        end

        it 'does not update the censor rule' do
          put :update, params: {
                         :id => censor_rule.id,
                         :censor_rule => { :text => 'different text' }
                       }
          censor_rule.reload
          expect(censor_rule.text).to eq('some text to redact')
        end

        it 'renders the form' do
          put :update, params: {
                         :id => censor_rule.id,
                         :censor_rule => { :text => 'different text' }
                       }

          expect(response).to render_template('edit')
        end

      end

    end

    context 'a CensorRule with an associated PublicBody' do

      let(:censor_rule) { FactoryBot.create(:public_body_censor_rule) }

      it 'finds the correct censor rule to edit' do
        put :update, params: {
                       :id => censor_rule.id,
                       :censor_rule => { :text => 'different text' }
                     }

        expect(assigns[:censor_rule]).to eq(censor_rule)
      end

      it 'sets the last_edit_editor to the current admin' do
        put :update, params: {
                       :id => censor_rule.id,
                       :censor_rule => { :text => 'different text' }
                     }

        expect(assigns[:censor_rule].last_edit_editor).to eq('*unknown*')
      end

      context 'successfully saving the censor rule' do

        it 'updates the censor rule' do
          put :update, params: {
                         :id => censor_rule.id,
                         :censor_rule => { :text => 'different text' }
                       }
          censor_rule.reload
          expect(censor_rule.text).to eq('different text')
        end

        it 'confirms the censor rule is updated' do
          put :update, params: {
                         :id => censor_rule.id,
                         :censor_rule => { :text => 'different text' }
                       }
          msg = 'Censor rule was successfully updated.'
          expect(flash[:notice]).to eq(msg)
        end

        it 'calls expire_requests on the censor_rule' do
          allow(CensorRule).to receive(:find) { censor_rule }
          allow(censor_rule).to receive(:expire_requests)
          put :update, params: {
                         :id => censor_rule.id,
                         :censor_rule => { :text => 'different text' }
                       }

          expect(censor_rule).to have_received(:expire_requests)
        end

        it 'redirects to the associated public body' do
          put :update, params: {
                         :id => censor_rule.id,
                         :censor_rule => { :text => 'different text' }
                       }

          expect(response).to redirect_to(
            admin_body_path(assigns[:censor_rule].public_body)
          )
        end

      end

      context 'unsuccessfully saving the censor rule' do

        before(:each) do
          allow_any_instance_of(CensorRule).to receive(:save).and_return(false)
        end

        it 'does not update the censor rule' do
          put :update, params: {
                         :id => censor_rule.id,
                         :censor_rule => { :text => 'different text' }
                       }
          censor_rule.reload
          expect(censor_rule.text).to eq('some text to redact')
        end

        it 'renders the form' do
          put :update, params: {
                         :id => censor_rule.id,
                         :censor_rule => { :text => 'different text' }
                       }

          expect(response).to render_template('edit')
        end

      end

    end

  end

  describe 'DELETE destroy' do

    context 'a global CensorRule' do

      let(:censor_rule) { FactoryBot.create(:global_censor_rule) }

      it 'finds the correct censor rule to destroy' do
        delete :destroy, params: { :id => censor_rule.id }
        expect(assigns[:censor_rule]).to eq(censor_rule)
      end

      it 'confirms the censor rule is destroyed in all cases' do
        delete :destroy, params: { :id => censor_rule.id }
        msg = 'Censor rule was successfully destroyed.'
        expect(flash[:notice]).to eq(msg)
      end

      it 'redirects to the censor rules index' do
        delete :destroy, params: { :id => censor_rule.id }
        expect(response).to redirect_to(admin_censor_rules_path)
      end

    end

    context 'a CensorRule with an associated InfoRequest' do

      let(:censor_rule) { FactoryBot.create(:info_request_censor_rule) }

      it 'finds the correct censor rule to destroy' do
        delete :destroy, params: { :id => censor_rule.id }
        expect(assigns[:censor_rule]).to eq(censor_rule)
      end

      it 'confirms the censor rule is destroyed in all cases' do
        delete :destroy, params: { :id => censor_rule.id }
        msg = 'Censor rule was successfully destroyed.'
        expect(flash[:notice]).to eq(msg)
      end

      it 'calls expire_requests on the censor rule' do
        expect(CensorRule).to receive(:find) { censor_rule }
        allow(censor_rule).to receive(:expire_requests)
        delete :destroy, params: { :id => censor_rule.id }

        expect(censor_rule).to have_received(:expire_requests)
      end

      it 'redirects to the associated info request' do
        delete :destroy, params: { :id => censor_rule.id }
        expect(response).
          to redirect_to(admin_request_path(censor_rule.info_request))
      end

    end

    context 'a CensorRule with an associated User' do

      let(:censor_rule) { FactoryBot.create(:user_censor_rule) }

      it 'finds the correct censor rule to destroy' do
        delete :destroy, params: { :id => censor_rule.id }
        expect(assigns[:censor_rule]).to eq(censor_rule)
      end

      it 'confirms the censor rule is destroyed in all cases' do
        delete :destroy, params: { :id => censor_rule.id }
        msg = 'Censor rule was successfully destroyed.'
        expect(flash[:notice]).to eq(msg)
      end

      it 'calls expire_requests on the censor rule' do
        expect(CensorRule).to receive(:find) { censor_rule }
        allow(censor_rule).to receive(:expire_requests)
        delete :destroy, params: { :id => censor_rule.id }

        expect(censor_rule).to have_received(:expire_requests)
      end

      it 'redirects to the associated info request' do
        delete :destroy, params: { :id => censor_rule.id }
        expect(response).to redirect_to(admin_user_path(censor_rule.user))
      end

    end

    context 'a CensorRule with an associated PublicBody' do

      let(:censor_rule) { FactoryBot.create(:public_body_censor_rule) }

      it 'finds the correct censor rule to destroy' do
        delete :destroy, params: { :id => censor_rule.id }
        expect(assigns[:censor_rule]).to eq(censor_rule)
      end

      it 'confirms the censor rule is destroyed in all cases' do
        delete :destroy, params: { :id => censor_rule.id }
        msg = 'Censor rule was successfully destroyed.'
        expect(flash[:notice]).to eq(msg)
      end

      it 'calls expire_requests on the censor rule' do
        expect(CensorRule).to receive(:find) { censor_rule }
        allow(censor_rule).to receive(:expire_requests)
        delete :destroy, params: { :id => censor_rule.id }

        expect(censor_rule).to have_received(:expire_requests)
      end

      it 'redirects to the associated public body' do
        delete :destroy, params: { :id => censor_rule.id }
        expect(response).
          to redirect_to(admin_body_path(censor_rule.public_body))
      end

    end

  end

end
