RSpec.shared_context 'consider all requests local', local_requests: true do
  include_context 'show exceptions'

  around do |example|
    config = Rails.application.config
    consider_all_requests_local = config.consider_all_requests_local
    config.consider_all_requests_local = true

    example.run

    config.consider_all_requests_local = consider_all_requests_local
  end
end

RSpec.shared_context 'consider all requests remote', local_requests: false do
  include_context 'show exceptions'

  around do |example|
    config = Rails.application.config
    consider_all_requests_local = config.consider_all_requests_local
    config.consider_all_requests_local = false

    example.run

    config.consider_all_requests_local = consider_all_requests_local
  end
end
