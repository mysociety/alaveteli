# -*- encoding : utf-8 -*-
require 'spec_helper'
require File.expand_path(File.dirname(__FILE__) + '/alaveteli_dsl')

describe "Signing in" do
  let(:user){ FactoryBot.create(:user) }

  def try_login(user, options = {})
    default_options = { :email => user.email,
                        :password => 'jonespassword' }
    options = default_options.merge(options)
    login_url = 'en/profile/sign_in'
    login_url += "?r=#{options[:redirect]}" if options[:redirect]
    visit login_url
    within '#signin_form' do
      fill_in "Your e-mail:", :with => options[:email]
      fill_in "Password:", :with => options[:password]
      click_button "Sign in"
    end
  end

  it "shows you an error if you get the password wrong" do
    try_login(user, { :password => 'badpassword' })
    expect(page).
      to have_content('Either the email or password was not recognised')
  end

  it "shows you an error if you get the email wrong" do
    try_login(user, { :email => 'wrong@localhost' })
    expect(page).
      to have_content('Either the email or password was not recognised')
  end

  context 'when you give the right credentials' do

    it 'logs you in' do
      try_login(user, { :redirect => '/list' })
      expect(page).
        to have_content user.name
    end

    it "it redirects to the redirect path" do
      try_login(user, { :redirect => '/list' })
      expect(page).
        to have_current_path '/list?post_redirect=1'
    end

    it 'does not redirect to another domain' do
      try_login(user, { :redirect => 'http://bad.place.com/list' })
      expect(page).
        to have_current_path('/list?post_redirect=1')
    end

    context 'if an account is not confirmed' do
      let(:user) { FactoryBot.create(:user, :email_confirmed => false) }

      it "sends a confirmation email_token, logs you in and redirects you" do
        try_login(user, { :redirect => '/list' })
        expect(page).to have_content 'Now check your email!'

        # check confirmation URL works
        visit confirmation_url_from_email
        expect(page).to have_content user.name
        expect(page).to have_current_path '/list?post_redirect=1'
      end

      context 'if an admin clicks the confirmation link' do
        let(:admin_user) { FactoryBot.create(:admin_user) }

        it "should keep you logged in if you click a confirmation link" do
          try_login(user, { :redirect => '/list' })
          expect(page).to have_content 'Now check your email!'

          # Log in as an admin
          using_session(login(admin_user)) do
            visit confirmation_url_from_email

            expect(page).to have_content admin_user.name

            # And the redirect should still work, of course
            expect(page).to have_current_path '/list?post_redirect=1'

          end
        end
      end
    end
  end
end
