# -*- encoding : utf-8 -*-
module AlaveteliDsl

  def browses_request(url_title)
    get "/request/#{url_title}"
    assert_response :success
  end

  def creates_request_unregistered
    params = { :info_request => { :public_body_id => public_bodies(:geraldine_public_body).id,
                                  :title => "Why is your quango called Geraldine?",
                                  :tag_string => "" },
               :outgoing_message => { :body => "This is a silly letter. It is too short to be interesting." },
               :submitted_new_request => 1,
               :preview => 0
               }

    # Initially we are not logged in. Try to create a new request.
    post "/new", params
    # We expect to be redirected to the login page
    post_redirect = PostRedirect.get_last_post_redirect
    expect(response).to redirect_to(:controller => 'user', :action => 'signin', :token => post_redirect.token)
    follow_redirect!
    expect(response).to render_template("user/sign")
    expect(response.body).to match(/To send your FOI request, create an account or sign in/)
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
