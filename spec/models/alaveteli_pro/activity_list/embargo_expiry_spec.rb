require 'spec_helper'

describe AlaveteliPro::ActivityList::EmbargoExpiry do
  include Rails.application.routes.url_helpers

  let!(:user) { FactoryBot.create(:user) }
  let!(:info_request) { FactoryBot.create(:info_request, :user => user) }
  let!(:event) { FactoryBot.create(:expire_embargo_event, :info_request => info_request) }
  let!(:activity) { described_class.new(event) }

  describe '#description' do

    it 'gives an appropriate description' do
      expect(activity.description).
        to eq 'Your request to {{public_body_name}} "{{info_request_title}}" ' \
              'is now public.'
    end

  end

  it_behaves_like "an ActivityList::Item with standard #description_urls"

  it_behaves_like "an ActivityList::Item with standard #call_to_action"

  describe '#call_to_action_url' do

    it 'returns the url of the info_request' do
      expect(activity.call_to_action_url).
        to eq request_path(info_request)
    end

  end

end
