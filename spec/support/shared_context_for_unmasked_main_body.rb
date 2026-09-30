# Only messages received on or after
# IncomingMessage::MainBody.unmasked_main_body_available_from can have their
# main body unmasked. Factories create messages with the current time, so specs
# that expect a message to be unmaskable fail when run before that date. This
# moves the date into the past for the duration of each example.
RSpec.shared_context 'unmasked main body available' do
  around do |example|
    main_body = IncomingMessage::MainBody
    available_from = main_body.unmasked_main_body_available_from
    main_body.unmasked_main_body_available_from = 1.year.ago

    example.run

    main_body.unmasked_main_body_available_from = available_from
  end
end
