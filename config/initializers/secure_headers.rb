# -*- encoding : utf-8 -*-
::SecureHeaders::Configuration.default do |config|

  # https://tools.ietf.org/html/rfc6797
  if AlaveteliConfiguration::force_ssl
    config.hsts = "max-age=#{20.years.to_i}; includeSubdomains; preload"
  end
  # https://tools.ietf.org/html/draft-ietf-websec-x-frame-options-02
  config.x_frame_options = "sameorigin"

  # http://msdn.microsoft.com/en-us/library/ie/gg622941%28v=vs.85%29.aspx
  config.x_content_type_options = "nosniff"

  # http://msdn.microsoft.com/en-us/library/dd565647%28v=vs.85%29.aspx
  config.x_xss_protection = "1; mode=block"

  # https://w3c.github.io/webappsec/specs/content-security-policy/
  config.csp = {
    # "meta" values. these will shaped the header, but the values are not included in the header.
    report_only:  true,

    # directive values: these values will directly translate into source directives
    default_src: %w(https: 'self'),
  }

  # https://www.nwebsec.com/HttpHeaders/SecurityHeaders/XDownloadOptions
  config.x_download_options = nil
end
