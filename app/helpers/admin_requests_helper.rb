module AdminRequestsHelper

  def reason_text(reason)
    method = "reason_text_#{ reason }"
    if respond_to?(method, true)
      send(method)
    else
      reason_text_default
    end
  end

  private

  def reason_text_default
    [
      _("We consider it to be vexatious, and have therefore hidden it from " \
        "other users."),
      _("You will still be able to view it while logged in to the site. " \
        "Please reply to this email if you would like to discuss this " \
        "decision further.")
    ].join(" ")
  end

  def reason_text_not_foi
    _("We consider it is not a valid FOI request, and have therefore hidden " \
      "it from other users.")
  end

end
