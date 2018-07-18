# -*- encoding : utf-8 -*-
require 'spec_helper'

shared_examples_for "PhaseCounts" do

  let(:model) { described_class }
  let(:class_name) { model.to_s }
  let(:factory) { class_name.demodulize.underscore }

  let(:resource) do
    resource = FactoryBot.build(factory)
    summary =
      AlaveteliPro::RequestSummary.
        create_or_update_from(FactoryBot.create(:info_request))
    resource.request_summaries << summary
    summary =
      AlaveteliPro::RequestSummary.
        create_or_update_from(FactoryBot.create(:info_request))
    resource.request_summaries << summary
    overdue = Delorean.time_travel_to(2.months.ago) do
      FactoryBot.create(:info_request)
    end
    summary = AlaveteliPro::RequestSummary.create_or_update_from(overdue)
    resource.request_summaries << summary
    resource.save!
    resource
  end

  describe '#phase_counts' do

    it 'returns a Hash' do
      expect(resource.phase_counts).to be_a(Hash)
    end

    it 'returns the number of requests for the given phase key' do
      expect(resource.phase_counts['awaiting_response']).to eq 2
    end

    it 'accepts a symbol key' do
      expect(resource.phase_counts[:awaiting_response]).to eq 2
    end

    it 'returns 0 if there is no matching phase key' do
      expect(resource.phase_counts['imadethisup']).to eq 0
    end

    it 'calculates the number of requests which are not drafts' do
      expect(resource.phase_counts['not_drafts']).to eq 3
    end

    context 'with draft requests' do
      before do
        draft =
          AlaveteliPro::RequestSummary.create_or_update_from(
            FactoryBot.create(:draft_info_request)
          )
        resource.request_summaries << draft
        resource.save!
      end

      it 'counts the draft requests' do
        expect(resource.phase_counts['draft']).to eq 1
      end

      it 'does not include draft requests in the not_drafts total' do
        expect(resource.phase_counts['not_drafts']).to eq 3
      end

    end

    context 'with expiring embargoes' do
      before do
        embargo = AlaveteliPro::RequestSummary.create_or_update_from(
          FactoryBot.create(:embargo_expiring_request)
        )
        resource.request_summaries << embargo
        resource.save!
      end

      it 'counts the expiring embargoes' do
        expect(resource.phase_counts['embargo_expiring']).to eq 1
      end

      it 'includes the expiring embargo request in the phase total' do
        expect(resource.phase_counts['awaiting_response']).to eq 3
      end

      it 'does not double count the expiring embargo in the not_drafts total' do
        expect(resource.phase_counts['not_drafts']).to eq 4
      end

    end

    it 'caches the results' do
      before = resource.phase_counts['awaiting_response']
      summary =
        AlaveteliPro::RequestSummary.
          create_or_update_from(FactoryBot.create(:info_request))
      resource.request_summaries << summary
      resource.save!
      expect(resource.phase_counts['awaiting_response']).to eq(before)
    end

  end

  describe '#phase_counts!' do

    it 'resets the cache so the results are recalcuated' do
      before = resource.phase_counts!['awaiting_response']
      summary =
        AlaveteliPro::RequestSummary.
          create_or_update_from(FactoryBot.create(:info_request))
      resource.request_summaries << summary
      resource.save!
      expect(resource.phase_counts!['awaiting_response']).to eq(before + 1)
    end

  end

end
