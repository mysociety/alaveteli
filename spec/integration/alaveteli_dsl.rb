# -*- encoding : utf-8 -*-
module AlaveteliDsl

  def browse_request(url_title)
    visit "/request/#{url_title}"
  end

  def create_request
    visit select_authority_path
    within(:css, '#search_form') do
      fill_in 'query', :with => 'Geraldine Quango'
      find_button('Search').click
    end
    within(:css, '.body_listing') do
      find_link('Make a request').click
    end
    fill_in 'Summary:', :with => "Why is your quango called Geraldine?"
    fill_in 'Your request:', :with => "This is a silly letter. It is too short to be interesting."

    find_button('Preview your public request').click
    find_button('Send request').click
    expect(page).to have_content('To send your FOI request, create an account or sign in')
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

def login(user)
  u = user.is_a?(User) ? user : users(user)
  alaveteli_session(u.id) do
    visit signin_path
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

def cache_directories_exist?(request)
  cache_path = File.join(Rails.root, 'cache', 'views')
  paths = [File.join(cache_path, 'request', request.request_dirs)]
  I18n.available_locales.each do |locale|
    paths << File.join(cache_path, locale.to_s, 'request', request.request_dirs)
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
