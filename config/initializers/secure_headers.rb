# -*- encoding : utf-8 -*-
::SecureHeaders::Configuration.default do |config|

  # https://tools.ietf.org/html/rfc6797
  if AlaveteliConfiguration::force_ssl
    config.hsts = "max-age=#{20.years.to_i}; includeSubdomains"
  else
    config.hsts = SecureHeaders::OPT_OUT #don't send on non https sites
  end

  # https://tools.ietf.org/html/draft-ietf-websec-x-frame-options-02
  config.x_frame_options = "sameorigin"

  # http://msdn.microsoft.com/en-us/library/ie/gg622941%28v=vs.85%29.aspx
  config.x_content_type_options = "nosniff"

  # http://msdn.microsoft.com/en-us/library/dd565647%28v=vs.85%29.aspx
  config.x_xss_protection = "1"

  # https://w3c.github.io/webappsec/specs/content-security-policy/
  config.csp = SecureHeaders::OPT_OUT

  # https://www.nwebsec.com/HttpHeaders/SecurityHeaders/XDownloadOptions
  config.x_download_options = SecureHeaders::OPT_OUT
end

 # Allow individual actions to allow frames
::SecureHeaders::Configuration.override(:allow_frames) do |config|
  config.x_frame_options = SecureHeaders::OPT_OUT
end
