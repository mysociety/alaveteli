# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AlaveteliPro::ToDoList::VeryOverdueRequest do
  include Rails.application.routes.url_helpers

  let(:info_request){ FactoryGirl.create(:info_request) }

  before do
    time_travel_to(Date.parse('2015-11-01')){ info_request }
    @very_overdue_request = described_class.new(info_request.user)
  end

  describe '#description' do

    it 'gives a description for one response' do
      time_travel_to(Date.parse('2016-01-01')) do
        expect(@very_overdue_request.description).to eq "1 request is very overdue."
      end
    end

    it 'gives a description for multiple responses' do
      time_travel_to(Date.parse('2015-11-01')) do
        FactoryGirl.create(:info_request, :user => info_request.user)
      end
      time_travel_to(Date.parse('2016-01-01')) do
        expect(@very_overdue_request.description).to eq "2 requests are very overdue."
      end
    end

  end

  describe '#items' do

    it 'returns the requests that are very overdue' do
      time_travel_to(Date.parse('2016-01-01')) do
        expect(@very_overdue_request.items).to eq [info_request]
      end
    end

  end

  describe '#url' do

    context 'when there is one item' do

      it 'returns a link to the request' do
        time_travel_to(Date.parse('2016-01-01')) do
          expect(@very_overdue_request.url).to eq show_request_path(info_request.url_title)
        end
      end

    end

    context 'when there is more than one item' do

      it 'returns a link to the info request list with a "very_overdue" filter' do
        time_travel_to(Date.parse('2015-11-01')) do
          FactoryGirl.create(:info_request, :user => info_request.user)
        end
        time_travel_to(Date.parse('2016-01-01')) do
          expect(@very_overdue_request.url)
            .to eq alaveteli_pro_info_requests_path('request_filter[filter]' =>
                                                      'very_overdue')
        end
      end

    end

  end

  describe '#call_to_action' do

    context 'when there is one item' do

      it 'returns an appropriate text' do
        time_travel_to(Date.parse('2016-01-01')) do
          expect(@very_overdue_request.call_to_action)
            .to eq 'Request an internal review (or send another followup).'
        end
      end

    end

    context 'when there is more than one item' do

      it 'returns an appropriate text' do

        time_travel_to(Date.parse('2015-11-01')) do
          FactoryGirl.create(:info_request, :user => info_request.user)
        end
        time_travel_to(Date.parse('2016-01-01')) do
          expect(@very_overdue_request.call_to_action)
            .to eq 'Request internal reviews (or send other followups).'
        end
      end

    end

  end

end
