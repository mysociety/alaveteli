require 'spec_helper'

RSpec.describe Users::ProfilePhotosController do
  describe 'POST set_profile_photo' do
    context 'user is banned' do
      before(:each) do
        @user = FactoryBot.create(:user, ban_text: 'Causing trouble')
        sign_in @user
        @uploadedfile = fixture_file_upload("parrot.png")

        post :set_profile_photo, params: {
                                   id: @user.id,
                                   file: @uploadedfile,
                                   submitted_draft_profile_photo: 1,
                                   automatically_crop: 1
                                 }
      end

      it 'redirects to the profile page' do
        expect(response).to redirect_to(set_profile_photo_path)
      end

      it 'renders an error message' do
        msg = 'Suspended users cannot edit their profile'
        expect(flash[:error]).to eq(msg)
      end
    end
  end
end

RSpec.describe Users::ProfilePhotosController, "when using profile photos" do
  render_views

  before do
    @user = users(:bob_smith_user)

    @uploadedfile = fixture_file_upload("parrot.png")
    @uploadedfile_2 = fixture_file_upload("parrot.png")
  end

  it "should not let you change profile photo if you're not logged in as the user" do
    post :set_profile_photo, params: {
                               id: @user.id,
                               file: @uploadedfile,
                               submitted_draft_profile_photo: 1,
                               automatically_crop: 1
                             }
  end

  it "should return a 404 not a 500 when a profile photo has not been set" do
    expect(@user.profile_photo).to be_nil
    expect {
      get :get_profile_photo, params: { url_name: @user.url_name }
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "should let you change profile photo if you're logged in as the user" do
    expect(@user.profile_photo).to be_nil
    sign_in @user

    post :set_profile_photo, params: {
                               id: @user.id,
                               file: @uploadedfile,
                               submitted_draft_profile_photo: 1,
                               automatically_crop: 1
                             }

    expect(response).to redirect_to(
      controller: '/user',
      action: 'show',
      url_name: "bob_smith"
    )
    expect(flash[:notice]).to match(/Thank you for updating your profile photo/)

    @user.reload
    expect(@user.profile_photo).not_to be_nil
  end

  context 'there is no profile text' do
    let(:user) { FactoryBot.create(:user, about_me: '') }

    it 'prompts you to add profile text when adding a photo' do
      sign_in user

      profile_photo = ProfilePhoto.
                        create(data: load_file_fixture("parrot.png"),
                               user: user)

      post :set_profile_photo,
           params: {
             id: user.id,
             file: @uploadedfile,
             submitted_crop_profile_photo: 1,
             draft_profile_photo_id: profile_photo.id
           }

      expect(flash[:notice][:partial]).
        to eq("users/profile_photos/update_profile_photo")
    end
  end

  it "should let you change profile photo twice" do
    expect(@user.profile_photo).to be_nil
    sign_in @user

    post :set_profile_photo, params: {
                               id: @user.id,
                               file: @uploadedfile,
                               submitted_draft_profile_photo: 1,
                               automatically_crop: 1
                             }
    expect(response).to redirect_to(
      controller: '/user',
      action: 'show',
      url_name: "bob_smith"
    )
    expect(flash[:notice]).to match(/Thank you for updating your profile photo/)

    post :set_profile_photo, params: {
                               id: @user.id,
                               file: @uploadedfile_2,
                               submitted_draft_profile_photo: 1,
                               automatically_crop: 1
                             }
    expect(response).to redirect_to(
      controller: '/user',
      action: 'show',
      url_name: "bob_smith"
    )
    expect(flash[:notice]).to match(/Thank you for updating your profile photo/)

    @user.reload
    expect(@user.profile_photo).not_to be_nil
  end

  # TODO: todo check the two stage javascript cropping (above only tests one
  # stage non-javascript one)
end
