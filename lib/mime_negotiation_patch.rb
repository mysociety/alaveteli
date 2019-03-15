module ActionDispatch::Http::MimeNegotiation

  def formats
    @env["action_dispatch.request.formats"] ||=
      if parameters[:format]
        Array(Mime[parameters[:format]])
      elsif use_accept_header && valid_accept_header
        accepts
      elsif xhr?
        [Mime::JS]
      else
        [Mime::HTML]
      end
  end

end
