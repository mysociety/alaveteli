RSpec::Matchers.define :a_new_response_event_for do |info_request|
  match do |actual|
    actual.event_type == 'response' \
      && actual.info_request.id == info_request.id
  end
end
