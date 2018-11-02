module AdminRequestsHelper

  def reason_text(reason, public_body = nil)
    method = "reason_text_#{ reason }"
    if respond_to?(method, true)
      send(method, public_body)
    else
      reason_text_default
    end
  end

  def supported_reasons
    %w(not_foi vexatious immigration_correspondence)
  end

  private

  def reason_text_default(public_body = nil)
    [
      _("We consider it to be vexatious, and have therefore hidden it from " \
        "other users."),
      _("You will still be able to view it while logged in to the site. " \
        "Please reply to this email if you would like to discuss this " \
        "decision further.")
    ].join(" ")
  end

  def reason_text_not_foi(public_body = nil)
    _("We consider it is not a valid FOI request, and have therefore hidden " \
      "it from other users.")
  end

  def reason_text_immigration_correspondence(public_body = nil)
    _("As it is personal correspondence which it wasn't appropriate to " \
      "send via our public website we have hidden it from other users. " \
      "You will still be able to view it while logged in to the site.")
  end

end
