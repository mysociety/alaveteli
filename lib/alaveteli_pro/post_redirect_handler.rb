module AlaveteliPro
  module PostRedirectHandler

    # A hook for us to override certain post redirects for pro users, e.g.
    # if they start making a request, then we realise they're a pro when they
    # log in, so we want to send them into the pro system
    def override_post_redirect_for_pro(uri, post_redirect, user)
      # We could have a locale in the url, or we could not, e.g. /en/new or /new
      if uri =~ /^(\/[a-z]{2})?\/new$/
        # Create a draft for the new request, then send the user to the new form
        # with their data prefilled and a message about creating an embargo.
        params = post_redirect.post_params
        draft = DraftInfoRequest.create(
          user: user,
          title: params["info_request"]["title"],
          body: params["outgoing_message"]["body"],
          public_body_id: params["info_request"]["public_body_id"])
        # Clear out the post_redirect, so that we don't get a lot of other
        # params put into our URL later on
        post_redirect.post_params = {}
        post_redirect.save
        flash[:notice] = _("Thanks for logging in. We've saved your " \
                           "request as a draft, in case you wanted to " \
                           "add an embargo before sending it. You can " \
                           "set that (or just send it straight away) " \
                           "using the form below.")
        return "#{new_alaveteli_pro_info_request_path}?draft_id=#{draft.id}"
      end
      return uri
    end

  end
end
