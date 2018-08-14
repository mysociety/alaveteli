# -*- encoding : utf-8 -*-
require 'spec_helper'
require File.expand_path(File.dirname(__FILE__) + '/alaveteli_dsl')

describe 'Updating your user profile' do

  let(:user) { FactoryBot.create(:user) }

  describe 'updating about_me text' do

    context "no profile picture set" do

      it "page displays thank you message with nudge to upload photo" do
        using_session(login(user)) do
          msg = "Thanks for changing the text about you on your " \
                "profile.Next... You can " \
                "upload a profile photograph too."
          visit edit_profile_about_me_path
          fill_in :user_about_me, :with => "I am a researcher"
          click_button "Save"

          expect(page).to have_content(msg)
        end
      end

    end

    context "with profile picture set" do

      before do
        user.create_profile_photo!(:data => load_file_fixture('parrot.png'))
      end

      it "displays a thank you message without upload photo nudge" do
        using_session(login(user)) do
          msg = "You have now changed the text about you on your profile."
          visit edit_profile_about_me_path
          fill_in :user_about_me, :with => "I am a researcher"
          click_button "Save"

          expect(page).to have_content(msg)
        end
      end

    end

  end

  describe 'adding a photo' do

    let(:photo_file) { File.absolute_path('./spec/fixtures/files/parrot.jpg') }

    context "no about_me text set" do

      it "page displays thank you message with nudge to upload photo" do
        using_session(login(user)) do
          msg = "Thanks for updating your profile photo." \
                "Next... You can put some text about " \
                "you and your research on your profile."

          # post the form to work around the Next button being drawn
          # by JavaScript
          profile_photo = ProfilePhoto.
                            create(:data => load_file_fixture("parrot.png"),
                                   :user => user)

          page.driver.post set_profile_photo_path,
               :id => user.id,
               :file => photo_file,
               :submitted_crop_profile_photo => 1,
               :draft_profile_photo_id => profile_photo.id

          visit page.driver.response.location
          expect(page).to have_content(msg)
        end
      end

    end

    context "with about_me text set" do

      before do
        user.about_me = "I am a test user"
      end

      it "page displays thank you message with nudge to upload photo" do
        using_session(login(user)) do
          msg = "Thank you for updating your profile photo"
          visit set_profile_photo_path

          attach_file('file_1', photo_file)

          find('input[value="Done >>"]').click

          expect(page).to have_content(msg)
        end
      end

    end
  end

end
