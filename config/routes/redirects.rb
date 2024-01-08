info_request_redirect = redirect do |params, request|
  # find request
  info_request = InfoRequest.find(params.fetch(:id))

  # check if current user can read the request
  ability = Ability.new(User.authenticate_from_session(request.session))
  raise ActiveRecord::RecordNotFound if ability.cannot?(:read, info_request)

  # split path components
  suffix = params[:suffix]&.split('/') # suffix is optional

  # encode path components
  encoded_parts = [
    *params[:locale], 'request', info_request.url_title, *suffix
  ].map do |part|
    if RUBY_VERSION < '3.1'
      URI.encode_www_form_component(part).gsub('+', '%20')
    else
      URI.encode_uri_component(part)
    end
  end

  # join encoded parts together with slashes
  encoded_parts.join('/')
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
