# -*- encoding : utf-8 -*-
module AlaveteliDsl

  def browse_request(url_title)
    visit "/request/#{url_title}"
  end

  def browse_pro_request(url_title)
    visit "/alaveteli_pro/info_requests/#{url_title}"
  end

  def create_request(public_body)
    visit select_authority_path
    within(:css, '#search_form') do
      fill_in 'query', :with => public_body.name
      find_button('Search').click
    end
    within(:css, '.body_listing') do
      find_link('Make a request').click
    end
    fill_in 'Summary', :with => "Why is your quango called Geraldine?"
    fill_in 'Your request', :with => "This is a silly letter. It is too short to be interesting."

    find_button('Preview your public request').click
    find_button('Send and publish request').click
    expect(page).to have_content('To send and publish your FOI request, create an account or sign in')
  end

  def create_request_and_user(public_body)
    user = FactoryGirl.build(:user)
    # Make a request in the normal way
    using_session(without_login) do
      create_request(public_body)
      # Now log in as an unconfirmed user.
      visit signin_path :token => get_last_post_redirect.token
      within '#signup_form' do
        fill_in "Your name:", :with => user.name
        fill_in "Your e-mail:", :with => user.email
        fill_in "Password:", :with => 'jonespassword'
        fill_in "Confirm password:", :with => 'jonespassword'
        click_button "Sign up"
      end
      expect(page).to have_content('Now check your email!')
    end

    # This will trigger a confirmation mail. Return the PostRedirect
    get_last_post_redirect
  end

  # Visit and fill out the pro-specific new request form
  # Note: you'll need to be logged in as a pro user to access this page.
  def create_pro_request(public_body)
    visit new_alaveteli_pro_info_request_path
    expect(page).to have_content "Make a request"

    fill_in "To", with: public_body.name
    click_button "Search"

    within ".body_listing" do
      find_link('Make a request').click
    end

    fill_in "Subject", with: "Does the pro request form work?"
    fill_in "Your request", with: "A very short letter."
    select "3 Months", from: "Privacy"
  end

  def add_body_to_pro_batch(public_body)
    within ".batch-builder__search-results li[data-body-id=\"#{public_body.id}\"]" do
      click_button "+ Add"
    end
  end
end

def hide_incoming_message(incoming_message, prominence, reason)
  visit edit_admin_incoming_message_path(incoming_message)
  select prominence, :from => 'Prominence'
  fill_in 'Reason for prominence', :with => reason
  find_button('Save').click
end

def hide_outgoing_message(outgoing_message, prominence, reason)
  visit edit_admin_outgoing_message_path(outgoing_message)
  select prominence, :from => 'Prominence'
  fill_in 'Reason for prominence', :with => reason
  find_button('Save').click
end

def alaveteli_session(session_id)
  using_session session_id do
    extend AlaveteliDsl
    yield
  end
end

def using_pro_session(session_id)
  with_feature_enabled(:alaveteli_pro) do
    using_session(session_id) do
      yield
    end
  end
end

def login(user)
  u = user.is_a?(User) ? user : users(user)
  alaveteli_session(u.id) do
    visit 'en/profile/sign_in'
    within '#signin_form' do
      fill_in "Your e-mail:", :with => u.email
      fill_in "Password:", :with => "jonespassword"
      click_button "Sign in"
    end
  end
  u.id
end

def without_login
  session_id = "without_login"
  using_session session_id do
    extend AlaveteliDsl
  end
  session_id
end

def confirm(user)
  u = users(user)
  u.email_confirmed = true
  u.save!
end

def close_request(request)
  request.allow_new_responses_from = 'nobody'
  request.handle_rejected_responses = 'holding_pen'
  request.save!
end

def holding_pen_messages
  InfoRequest.holding_pen_request.incoming_messages
end

def last_holding_pen_mail
  InfoRequest.holding_pen_request.get_last_public_response.raw_email
end

def confirmation_url_from_email
  deliveries = ActionMailer::Base.deliveries
  expect(deliveries.size).to eq(1)
  mail = deliveries.first
  mail.body.to_s =~ /(http:\/\/.*\/c\/.*)/
  $1
end

def cache_directories_exist?(request)
  cache_path = File.join(Rails.root, 'cache', 'views')
  paths = [File.join(cache_path, 'request', request.request_dirs)]
  AlaveteliLocalization.available_locales.each do |locale|
    paths << File.join(cache_path, locale, 'request', request.request_dirs)
  end
  paths.any?{ |path| File.exist?(path) }
end

def with_forgery_protection
  orig = ActionController::Base.allow_forgery_protection
  begin
    ActionController::Base.allow_forgery_protection = true
    yield if block_given?
  ensure
    ActionController::Base.allow_forgery_protection = orig
  end
end
