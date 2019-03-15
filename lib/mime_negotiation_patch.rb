# This monkeypatch backports the safer Rails 4.2 implementation of
# MimeNegotation#formats for Rails 3.2
module ActionDispatch::Http::MimeNegotiation

  def formats
    @env["action_dispatch.request.formats"] ||= begin
      params_readable = begin
                          parameters[:format]
                        rescue ActionController::BadRequest
                          false
                        end

      if params_readable
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

end
