# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AlaveteliPro::ToDoList::NewResponse do
  include Rails.application.routes.url_helpers

  let(:info_request) { FactoryBot.create(:old_unclassified_request) }
  let(:user) { info_request.user }

  before do
    @new_response = described_class.new(user)
    AlaveteliPro::RequestSummary.create_or_update_from(info_request)
  end

  describe '#description' do

    it 'gives a description for one response' do
      expect(@new_response.description).
        to eq "1 request has received a response."
    end

    it 'gives a description for multiple responses' do
      request = FactoryBot.create(:old_unclassified_request, user: user)
      AlaveteliPro::RequestSummary.create_or_update_from(request)
      expect(@new_response.description).
        to eq "2 requests have received a response."
    end

  end

  describe '#items' do

    it 'returns the requests that have received a response' do
      expect(@new_response.items).to eq [info_request]
    end

  end

  describe '#url' do

    context 'when there is one item' do

      it 'returns a link to the request' do
        expect(@new_response.url).to eq show_request_path(info_request.url_title)
      end

    end

    context 'when there is more than one item' do

      it 'returns a link to the info request list with a "response_received" filter' do
        request = FactoryBot.create(:old_unclassified_request, user: user)
        AlaveteliPro::RequestSummary.create_or_update_from(request)
        expect(@new_response.url).
          to eq alaveteli_pro_info_requests_path('alaveteli_pro_request_filter[filter]' =>
                                                    'response_received')
      end

    end

  end

  describe '#call_to_action' do

    context 'when there is one item' do

      it 'returns an appropriate text' do
        expect(@new_response.call_to_action).to eq 'Update its status.'
      end

    end

    context 'when there is more than one item' do

      it 'returns an appropriate text' do
        request = FactoryBot.create(:old_unclassified_request, user: user)
        AlaveteliPro::RequestSummary.create_or_update_from(request)
        expect(@new_response.call_to_action).to eq 'Update statuses.'
      end

    end

  end

end
