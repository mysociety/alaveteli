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
    response.body.should match(/To send your FOI request, please sign in or make a new account./)
  end

end

def login(user)
  open_session do |sess|
    # Make sure we get a fresh empty session - there seems to be some
    # problem with session leakage otherwise
    sess.reset!
    sess.extend(AlaveteliDsl)

    if user.is_a? User
        u = user
    else
        u = users(user)
    end
    sess.visit signin_path
    sess.fill_in "Your e-mail:", :with => u.email
    sess.fill_in "Password:", :with => "jonespassword"
    sess.click_button "Sign in"
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



