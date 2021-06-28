require 'spec_helper'

describe AlaveteliPro::ActivityList::NewResponse do
  include Rails.application.routes.url_helpers

  let(:event) { FactoryBot.create(:response_event) }
  let(:activity) { described_class.new(event) }

  describe '#description' do

    it 'gives an appropriate description' do
      expect(activity.description).
        to eq 'Your request to {{public_body_name}}' \
              ' "{{info_request_title}}" received a new response.'
    end

  end

  it_behaves_like "an ActivityList::Item with standard #description_urls"

  it_behaves_like "an ActivityList::Item with standard #call_to_action"

  describe '#call_to_action_url' do

    it 'returns the url of the response' do
      expect(activity.call_to_action_url).
        to eq incoming_message_path(event.incoming_message)
    end

  end

end
