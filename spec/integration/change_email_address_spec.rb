# -*- encoding : utf-8 -*-
require 'spec_helper'
require File.expand_path(File.dirname(__FILE__) + '/alaveteli_dsl')

describe 'changing your email address' do
  let(:user) { FactoryBot.create(:user) }

  it "sends a confirmation email if you get all the details right" do

    using_session(login(user)) do
      visit signchangeemail_path
      fill_in "signchangeemail_old_email", :with => user.email
      fill_in "signchangeemail_password", :with => 'jonespassword'
      fill_in "signchangeemail_new_email", :with => 'newbob@localhost'
      click_button "Change email on Alaveteli"

      expect(page).to have_content('Now check your email!')

      mail = ActionMailer::Base.deliveries.first
      expect(mail.body).to include("confirm that you want to change")
      expect(mail.to).to eq([ 'newbob@localhost' ])

      # Check confirmation URL works
      visit confirmation_url_from_email
      expect(page).to have_current_path("/en/user/#{user.url_name}")
      expect(page).to have_content('You have now changed your email address')
      user.reload
      expect(user.email).to eq('newbob@localhost')
      expect(user.email_confirmed).to eq(true)
    end
  end
end
