require 'spec_helper'

RSpec.describe UploadResponseController, type: :controller do
  describe 'GET|POST #new' do
    before(:each) do
      # domain after the @ is used for authentication of FOI officers, so to test
      # it, we need a user which isn't at localhost.
      @normal_user = User.new(
        name: "Mr. Normal",
        email: "normal-user@flourish.org",
        password: PostRedirect.generate_random_token
      )
      @normal_user.save!

      @foi_officer_user = User.new(
        name: "The Geraldine Quango",
        email: "geraldine-requests@localhost",
        password: PostRedirect.generate_random_token
      )
      @foi_officer_user.save!
    end

    context 'when the request is embargoed' do
      let(:embargoed_request) { FactoryBot.create(:embargoed_request) }

      it 'raises an ActiveRecord::RecordNotFound error' do
        expect {
          get :new, params: { url_title: embargoed_request.url_title }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when user is signed out' do
      it 'redirect to the login page' do
        get :new, params: {
          url_title: 'why_do_you_have_such_a_fancy_dog'
        }
        expect(response).
          to redirect_to(signin_path(token: get_last_post_redirect.token))
      end
    end

    it "should require login to view the form to upload" do
      @ir = info_requests(:fancy_dog_request)
      expect(@ir.public_body.is_foi_officer?(@normal_user)).to eq(false)
      sign_in @normal_user

      get :new, params: {
        url_title: 'why_do_you_have_such_a_fancy_dog'
      }
      expect(response).to render_template('user/wrong_user')
    end

    context 'when the request is closed to responses' do
      let(:closed_request) do
        FactoryBot.create(:info_request, allow_new_responses_from: 'nobody')
      end
      it "should prevent uploads if closed to all responses" do
        sign_in @normal_user
        get :new, params: { url_title: closed_request.url_title }
        expect(response).to render_template(
          'request/request_subtitle/allow_new_responses_from/_nobody'
        )
      end
    end

    context 'when the domain is restricted' do
      before do
        PublicBody.excluded_foi_officer_access_domains << 'example.com'
      end

      after do
        PublicBody.excluded_foi_officer_access_domains.delete('example.com')
      end

      it 'says only the main foi address can be used' do
        @ir = info_requests(:fancy_dog_request)
        @ir.public_body.update(request_email: 'foi@example.com')
        @foi_officer_user.update(email: 'david@example.com')

        expect(@ir.public_body.is_foi_officer?(@foi_officer_user)).
          to eq(false)

        sign_in @foi_officer_user

        get :new, params: {
          url_title: 'why_do_you_have_such_a_fancy_dog'
        }

        expect(response).to render_template('user/wrong_user')

        expect(assigns(:reason_params)[:user_name]).
          to match(/main FOI address/)
      end
    end

    it "should let you view upload form if you are an FOI officer" do
      @ir = info_requests(:fancy_dog_request)
      expect(@ir.public_body.is_foi_officer?(@foi_officer_user)).to eq(true)
      sign_in @foi_officer_user

      get :new, params: {
        url_title: 'why_do_you_have_such_a_fancy_dog'
      }
      expect(response).to render_template('upload_response/new')
    end

    it "should prevent uploads if you are not a requester" do
      @ir = info_requests(:fancy_dog_request)
      incoming_before = @ir.incoming_messages.count
      sign_in @normal_user

      # post up a photo of the parrot
      parrot_upload = fixture_file_upload('parrot.png', 'image/png')
      post :new, params: {
        url_title: 'why_do_you_have_such_a_fancy_dog',
        body: "Find attached a picture of a parrot",
        file_1: parrot_upload,
        submitted_upload_response: 1
      }
      expect(response).to render_template('user/wrong_user')
    end

    it "should prevent entirely blank uploads" do
      sign_in @foi_officer_user

      post :new, params: {
        url_title: 'why_do_you_have_such_a_fancy_dog',
        body: "", submitted_upload_response: 1
      }
      expect(response).to render_template('upload_response/new')
      expect(flash[:error]).to match(/Please type a message/)
    end

    it 'should 404 for non existent requests' do
      expect {
        post :new, params: { url_title: 'i_dont_exist' }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    # How do I test a file upload in rails?
    # http://stackoverflow.com/questions/1178587/how-do-i-test-a-file-upload-in-rails
    it "should let the authority upload a file" do
      @ir = info_requests(:fancy_dog_request)
      incoming_before = @ir.incoming_messages.count
      sign_in @foi_officer_user

      # post up a photo of the parrot
      parrot_upload = fixture_file_upload('parrot.png', 'image/png')
      post :new, params: {
        url_title: 'why_do_you_have_such_a_fancy_dog',
        body: "Find attached a picture of a parrot",
        file_1: parrot_upload,
        submitted_upload_response: 1
      }

      expect(response).to redirect_to(
        show_request_path(url_title: 'why_do_you_have_such_a_fancy_dog')
      )
      expect(flash[:notice]).
        to match(/Thank you for responding to this FOI request/)

      # check there is a new attachment
      incoming_after = @ir.incoming_messages.count
      expect(incoming_after).to eq(incoming_before + 1)

      # check new attachment looks vaguely OK
      new_im = @ir.incoming_messages[-1]
      expect(new_im.get_main_body_text_unfolded).
        to match(/Find attached a picture of a parrot/)
      attachments = new_im.get_attachments_for_display
      expect(attachments.size).to eq(1)
      expect(attachments[0].filename).to eq("parrot.png")
      expect(attachments[0].display_size).to eq("94K")
    end
  end
end
