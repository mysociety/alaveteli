# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AlaveteliPro::ActivityList::Overdue do
  include Rails.application.routes.url_helpers

  let(:event){ FactoryBot.create(:overdue_event) }
  let(:activity){ described_class.new(event) }

  describe '#description' do

    it 'gives an appropriate description' do
      expect(activity.description).
        to eq '{{public_body_name}} are delayed in responding to your' \
              ' request "{{info_request_title}}".'
    end

  end

  it_behaves_like "an ActivityList::Item with standard #description_urls"

  describe '#call_to_action' do

    it 'returns the text "Send a follow up"' do
      expect(activity.call_to_action).to eq('Send a follow up')
    end

  end

  describe '#call_to_action_url' do

    it 'returns the url of the info_request' do
      expect(activity.call_to_action_url).
        to eq new_request_followup_path(:request_id => event.info_request.id,
                                        :anchor => 'followup')
    end

  end

end
