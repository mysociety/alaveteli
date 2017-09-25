# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AlaveteliPro::ToDoList::OverdueRequest do
  include Rails.application.routes.url_helpers

  let(:info_request) { FactoryGirl.create(:info_request) }
  let(:user) { info_request.user }

  before do
    time_travel_to(Date.parse('2015-11-01')){ info_request }
    @overdue_request = described_class.new(user)
  end

  describe '#description' do

    it 'gives a description for one response' do
      time_travel_to(Date.parse('2015-12-01')) do
        expect(@overdue_request.description).to eq "1 request is delayed."
      end
    end

    it 'gives a description for multiple responses' do
      time_travel_to(Date.parse('2015-11-01')) do
        FactoryGirl.create(:info_request, :user => user)
      end
      time_travel_to(Date.parse('2015-12-01')) do
        expect(@overdue_request.description).to eq "2 requests are delayed."
      end
    end

  end

  describe '#items' do

    it 'returns the requests that are overdue' do
      time_travel_to(Date.parse('2015-12-01')) do
        expect(@overdue_request.items).to eq [info_request]
      end
    end

  end

  describe '#url' do

    context 'when there is one item' do

      it 'returns a link to the request' do
        time_travel_to(Date.parse('2015-12-01')) do
          expect(@overdue_request.url).to eq show_request_path(info_request.url_title)
        end
      end

    end

    context 'when there is more than one item' do

      it 'returns a link to the info request list with a "overdue" filter' do
        time_travel_to(Date.parse('2015-11-01')) do
          FactoryGirl.create(:info_request, :user => user)
        end
        time_travel_to(Date.parse('2015-12-01')) do
          expect(@overdue_request.url)
            .to eq alaveteli_pro_info_requests_path('alaveteli_pro_request_filter[filter]' =>
                                                      'overdue')
        end
      end

    end

  end

  describe '#call_to_action' do

    context 'when there is one item' do

      it 'returns an appropriate text' do
        time_travel_to(Date.parse('2015-12-01')) do
          expect(@overdue_request.call_to_action)
            .to eq 'Send a follow up (or request an internal review).'
        end
      end

    end

    context 'when there is more than one item' do

      it 'returns an appropriate text' do

        time_travel_to(Date.parse('2015-11-01')) do
          FactoryGirl.create(:info_request, :user => user)
        end
        time_travel_to(Date.parse('2015-12-01')) do
          expect(@overdue_request.call_to_action)
            .to eq 'Send follow ups (or request internal reviews).'
        end
      end

    end

  end

end
