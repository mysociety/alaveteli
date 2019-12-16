# frozen_string_literal: true
RSpec.configure do |config|
  config.before do
    stub_request(:get, %r|gaze.mysociety.org|).to_return(status: 200)
  end
end
