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

      post :set_profile_photo,
           params: { file: @uploadedfile, submitted_draft_profile_photo: 1 }
      post :set_profile_photo, params: { submitted_crop_profile_photo: 1 }

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

  context 'when cropping a draft photo' do
    let(:user) { FactoryBot.create(:user) }
    let(:other_user) { FactoryBot.create(:user) }

    let!(:other_photo) do
      ProfilePhoto.create!(data: load_file_fixture('parrot.png'),
                           user: other_user)
    end

    before { sign_in user }

    def upload_draft
      post :set_profile_photo,
           params: { file: @uploadedfile, submitted_draft_profile_photo: 1 }
      ProfilePhoto.find(session[:draft_profile_photo_id])
    end

    it 'sets the photo from the draft uploaded in this session' do
      draft = upload_draft
      post :set_profile_photo, params: { submitted_crop_profile_photo: 1 }

      expect(user.reload.profile_photo).to be_present
      expect(ProfilePhoto.exists?(draft.id)).to eq(false)
      expect(session[:draft_profile_photo_id]).to be_nil
    end

    it 'ignores a draft_profile_photo_id param' do
      expect {
        post :set_profile_photo,
             params: { submitted_crop_profile_photo: 1,
                       draft_profile_photo_id: other_photo.id }
      }.to raise_error(ActiveRecord::RecordNotFound)

      expect(ProfilePhoto.exists?(other_photo.id)).to eq(true)
      expect(user.reload.profile_photo).to be_nil
    end

    it 'does not use a non-draft photo referenced by the session' do
      session[:draft_profile_photo_id] = other_photo.id

      expect {
        post :set_profile_photo, params: { submitted_crop_profile_photo: 1 }
      }.to raise_error(ActiveRecord::RecordNotFound)

      expect(ProfilePhoto.exists?(other_photo.id)).to eq(true)
    end

    it 'does not change the photo on a GET request' do
      draft = ProfilePhoto.create!(data: load_file_fixture('parrot.png'),
                                   draft: true)
      session[:draft_profile_photo_id] = draft.id

      get :set_profile_photo, params: { submitted_crop_profile_photo: 1 }

      expect(response).to render_template(:set_draft_profile_photo)
      expect(user.reload.profile_photo).to be_nil
      expect(ProfilePhoto.exists?(draft.id)).to eq(true)
    end
  end
end

RSpec.describe Users::ProfilePhotosController, '#get_draft_profile_photo' do
  let(:draft) do
    ProfilePhoto.create!(data: load_file_fixture('parrot.png'), draft: true)
  end

  it 'returns the draft uploaded in this session' do
    session[:draft_profile_photo_id] = draft.id
    get :get_draft_profile_photo, params: { id: draft.id }, format: 'png'
    expect(response).to be_successful
    expect(response.media_type).to eq('image/png')
  end

  it 'does not return a draft to a session that did not upload it' do
    expect {
      get :get_draft_profile_photo, params: { id: draft.id }, format: 'png'
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'does not return a different draft to the uploading session' do
    other = ProfilePhoto.create!(data: load_file_fixture('parrot.png'),
                                 draft: true)
    session[:draft_profile_photo_id] = draft.id

    expect {
      get :get_draft_profile_photo, params: { id: other.id }, format: 'png'
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'does not return a published photo' do
    photo = ProfilePhoto.create!(data: load_file_fixture('parrot.png'),
                                 user: FactoryBot.create(:user))
    session[:draft_profile_photo_id] = photo.id

    expect {
      get :get_draft_profile_photo, params: { id: photo.id }, format: 'png'
    }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
