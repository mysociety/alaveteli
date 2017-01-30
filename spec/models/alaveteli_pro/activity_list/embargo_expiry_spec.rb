# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AlaveteliPro::ActivityList::EmbargoExpiry do
  include Rails.application.routes.url_helpers

  let!(:user){ FactoryGirl.create(:user) }
  let!(:info_request){ FactoryGirl.create(:info_request, :user => user) }
  let!(:event){ FactoryGirl.create(:expire_embargo_event, :info_request => info_request) }
  let!(:activity){ described_class.new(event) }

  describe '#description' do

    it 'gives an appropriate description' do
      expect(activity.description).
        to eq 'The embargo for your request to {{public_body_name}} ' \
              '"{{info_request_title}}" has ended so the request is now public.'
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
