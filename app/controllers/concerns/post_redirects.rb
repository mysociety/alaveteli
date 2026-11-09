##
# Saves a request that needs a signed in user as a PostRedirect, sends the
# user to sign in, and then replays the request with its saved params.
#
module PostRedirects
  extend ActiveSupport::Concern

  include AlaveteliPro::PostRedirectHandler

  private

  def ask_to_login(as: nil, **reason_params)
    if as
      reason_params[:user_name] = as.name
      reason_params[:user_url] = show_user_url(url_name: as.url_name)

      if authenticated?
        # They are already logged in, but as the wrong user
        @reason_params = reason_params
        render(template: 'user/wrong_user') && return
      end
    end

    post_redirect = reason_params.delete(:post_redirect)
    post_redirect ||= PostRedirect.new(uri: request.fullpath,
                                       post_params: params,
                                       reason_params: reason_params)
    post_redirect.save!

    # Make sure this redirect does not get cached - it only applies to this user
    # HTTP 1.1
    headers['Cache-Control'] =
      'private, no-cache, no-store, max-age=0, must-revalidate'
    # HTTP 1.0
    headers['Pragma'] = 'no-cache'
    # Proxies
    headers['Expires'] = '0'

    # 'modal' controls whether the sign-in form will be displayed in the typical
    # full-blown page or on its own, useful for pop-ups
    redirect_to signin_url(token: post_redirect.token, modal: params[:modal])

    false
  end

  # Do a POST redirect. This is a nasty hack - we store the posted values in
  # the session, and when the GET redirect with "?post_redirect=1" happens,
  # load them in.
  def do_post_redirect(post_redirect, user = nil)
    uri = SafeRedirect.new(post_redirect.uri).path
    if feature_enabled?(:alaveteli_pro) &&
       user &&
       user.is_pro? &&
       session[:admin_confirmation] != 1
      uri = override_post_redirect_for_pro(uri,
                                           post_redirect,
                                           user)
    end
    session[:post_redirect_token] = post_redirect.token
    uri = add_post_redirect_param_to_uri(uri)
    session.delete(:admin_confirmation)
    redirect_to uri
  end

  def add_post_redirect_param_to_uri(uri)
    add_query_params_to_url(uri, post_redirect: 1)
  end

  # If we are in a faked redirect to POST request, then set post params.
  def check_in_post_redirect
    return unless params[:post_redirect]

    if session[:post_redirect_token]
      post_redirect =
        PostRedirect.find_by_token(session[:post_redirect_token])
      if post_redirect
        post_redirect_params =
          params_to_unsafe_hash(post_redirect.post_params)
        params.merge!(post_redirect_params)
        params[:post_redirect_user] = post_redirect.user
      end
    else
      logger.warn "Missing post redirect token. " \
                  "Session: #{session.to_hash} " \
                  "IP: #{user_ip} " \
                  "Params: #{params}"
    end
  end
end
