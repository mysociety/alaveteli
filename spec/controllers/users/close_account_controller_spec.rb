# spec/controllers/users/close_account_controller_spec.rb
require 'spec_helper'

RSpec.describe Users::CloseAccountController, type: :controller do
  describe "POST #create" do
    let(:user) { FactoryBot.create(:user) }

    before do
      sign_in user
    end

    after do
      user.account_closure_request&.destroy
    end

    it "shows the user a confirmation page" do
      get :new
      assert_response :success
      expect(response).to render_template(:new)
    end

    it "asks the user to check the confirmation checkbox" do
      post :create, params: { confirm: "0" }
      assert_response :redirect
      expect(response).to redirect_to(users_close_account_path)
      expect(flash[:error]).to eq("You must confirm that you want to close your account")
    end

    it "creates a record of the user's request to close their account" do
      post :create, params: { confirm: "1" }

      user.reload
      expect(user.account_closure_request).to be_present

      # Check email has been sent
      expect(ActionMailer::Base.deliveries.count).to eq(1)
      email = ActionMailer::Base.deliveries.last
      expect(email.to).to eq([user.email])
      expect(email.subject).to eq("Your account closure request on #{site_name}")

      assert_response :redirect
      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to eq("Your account closure request has been received. We will be in touch.")
    end
  end
end
