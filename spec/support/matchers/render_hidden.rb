# Matches a response to hidden content: the given template rendered with a
# 403 (or custom) status, and a noindex header so search engines don't try to
# index it.
#
#   expect(response).to render_hidden
#   expect(response).to render_hidden('request/hidden_attachment')
#   expect(response).to render_hidden('request/hidden', status: 404)
#   expect(response).to render_hidden('request/hidden', media_type: 'text/html')
#
RSpec::Matchers.define :render_hidden do |template = 'request/hidden', status: 403, media_type: 'text/html'|
  match do |response|
    @template_matcher = render_template(template)

    @template_matcher.matches?(response) &&
      response.code == status.to_s &&
      response.media_type == media_type.to_s &&
      response.headers['X-Robots-Tag'] == 'noindex, nofollow'
  end

  failure_message do |response|
    problems = []

    unless @template_matcher.matches?(response)
      problems << @template_matcher.failure_message
    end

    unless response.media_type == media_type
      problems << "expected response media type #{media_type}, got " \
                  "#{response.media_type}"
    end

    unless response.code == status.to_s
      problems << "expected response code #{status}, got #{response.code}"
    end

    unless response.headers['X-Robots-Tag'] == 'noindex, nofollow'
      problems << 'expected X-Robots-Tag "noindex, nofollow", got ' \
                  "#{response.headers['X-Robots-Tag'].inspect}"
    end

    problems.join("\n")
  end
end
