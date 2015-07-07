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
    response.should redirect_to(:controller => 'user', :action => 'signin', :token => post_redirect.token)
    follow_redirect!
    response.should render_template("user/sign")
    response.body.should match(/To send your FOI request, create an account or sign in/)
  end

end

def login(user)
  open_session do |sess|
    # Make sure we get a fresh empty session - there seems to be some
    # problem with session leakage otherwise
    sess.reset!
    sess.extend(AlaveteliDsl)

    u = user.is_a?(User) ? user : users(user)

    sess.visit signin_path

    sess.within '#signin_form' do
        sess.fill_in "Your e-mail:", :with => u.email
        sess.fill_in "Password:", :with => "jonespassword"
        sess.click_button "Sign in"
    end

    assert sess.session[:user_id] == u.id
  end
end

def without_login
  open_session do |sess|
    sess.extend(AlaveteliDsl)
  end
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


