# -*- encoding : utf-8 -*-
::SecureHeaders::Configuration.configure do |config|

    # https://tools.ietf.org/html/rfc6797
    if AlaveteliConfiguration::force_ssl
        config.hsts = { :max_age => 20.years.to_i, :include_subdomains => true }
    else
        config.hsts = false
    end
    # https://tools.ietf.org/html/draft-ietf-websec-x-frame-options-02
    config.x_frame_options = "sameorigin"

    # http://msdn.microsoft.com/en-us/library/ie/gg622941%28v=vs.85%29.aspx
    config.x_content_type_options = "nosniff"

    # http://msdn.microsoft.com/en-us/library/dd565647%28v=vs.85%29.aspx
    config.x_xss_protection = { :value => 1 }

    # https://w3c.github.io/webappsec/specs/content-security-policy/
    config.csp = false

    # https://www.nwebsec.com/HttpHeaders/SecurityHeaders/XDownloadOptions
    config.x_download_options = false
end

