info_request_redirect = redirect do |params, request|
  # find request
  if params[:url_title]
    info_request = InfoRequest.find_by(url_title: params[:url_title])
  end
  info_request ||= InfoRequest.find(params[:id]) if params[:id]
  raise ActiveRecord::RecordNotFound unless info_request

  # check if current user can read the request
  ability = Ability.new(User.authenticate_from_session(request.session))
  raise ActiveRecord::RecordNotFound if ability.cannot?(:read, info_request)

  # split path components
  prefix = params[:prefix]&.split('/') # prefix is optional
  suffix = params[:suffix]&.split('/') # suffix is optional

  # encode path components
  encoded_parts = [
    *params[:locale], 'request', info_request.url_title, *prefix, *suffix
  ].map do |part|
    if RUBY_VERSION < '3.1'
      URI.encode_www_form_component(part).gsub('+', '%20')
    else
      URI.encode_uri_component(part)
    end
  end

  # join encoded parts together with slashes
  base = encoded_parts.join('/')
  params[:format] ? "#{base}.#{params[:format]}" : base
end

get '/request/:id',
  constraints: { id: /\d+/ },
  to: info_request_redirect

get '/request/:id(/*suffix)',
  constraints: { id: /\d+/, suffix: %r(followups/new(/\d+)?) },
  to: info_request_redirect

get '/request/:id(/*suffix)',
  format: false,
  constraints: { id: /\d+/, suffix: %r(response/\d+/attach(/html)?/\d+/.*) },
  to: info_request_redirect

get '/request/:id(/*suffix)',
  constraints: { id: /\d+/, suffix: %r(report/new) },
  to: info_request_redirect

get '/request/:id(/*suffix)',
  constraints: { id: /\d+/, suffix: %r(widget(/new)?) },
  to: info_request_redirect

get '/:prefix/request/:url_title',
  constraints: { prefix: 'details' },
  to: info_request_redirect

get '/:prefix/request/:url_title',
  constraints: { prefix: 'similar' },
  to: info_request_redirect

get '/:prefix/request/:url_title',
  constraints: { prefix: 'upload' },
  to: info_request_redirect

get '/:prefix/request/:url_title',
  constraints: { prefix: 'annotate' },
  to: info_request_redirect

get '/:prefix/request/:url_title',
  constraints: { prefix: /(track|feed)/ },
  to: info_request_redirect

get '/:prefix/request/:url_title',
  constraints: { prefix: 'categorise' },
  to: info_request_redirect

locale_constraint = ->(request) do
  path_locale = request.path.split('/')[1]
  begin
    locale = AlaveteliLocalization::Locale.parse(path_locale).canonicalize
    available = AlaveteliConfiguration.available_locales.split(' ').map do |l|
      AlaveteliLocalization::Locale.parse(l).canonicalize
    end
    available.include?(locale)
  rescue ArgumentError
    false
  end
end

get ':locale',
  constraints: locale_constraint,
  to: redirect('?locale=%{locale}')

get ':locale/*path',
  constraints: locale_constraint,
  to: redirect('%{path}?locale=%{locale}')

constraints FeatureConstraint.new(:alaveteli_pro) do
  get '/alaveteli_pro/info_requests/:url_title',
    constraints: { url_title: /(?!new).*/ },
    to: redirect('/request/%{url_title}')
end
