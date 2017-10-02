# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AlaveteliPro::PhaseCounts do
  let(:user) { FactoryGirl.create(:user) }

  describe '#phase_count' do

    before do
      AlaveteliPro::RequestSummary.
        create_or_update_from(FactoryGirl.create(:info_request, user: user))
      AlaveteliPro::RequestSummary.
        create_or_update_from(FactoryGirl.create(:info_request, user: user))
      overdue = Delorean.time_travel_to(1.month.ago) do
        FactoryGirl.create(:info_request, user: user)
      end
      AlaveteliPro::RequestSummary.create_or_update_from(overdue)
    end

    it 'returns the number of requests for the given phase key' do
      expect(user.phase_count('awaiting_response')).to eq 2
    end

    it 'accepts a symbol key' do
      expect(user.phase_count(:awaiting_response)).to eq 2
    end

    it 'returns 0 if there is no matching phase key' do
      expect(user.phase_count('imadethisup')).to eq 0
    end

    it 'calculates the number of requests which are not drafts' do
      expect(user.phase_count('not_drafts')).to eq 3
    end

    context 'with draft requests' do
      before do
        AlaveteliPro::RequestSummary.create_or_update_from(
          FactoryGirl.create(:draft_info_request, user: user)
        )
      end

      it 'counts the draft requests' do
        expect(user.phase_count('draft')).to eq 1
      end

      it 'does not include draft requests in the not_drafts total' do
        expect(user.phase_count('not_drafts')).to eq 3
      end

    end

    context 'with expiring embargoes' do
      before do
        AlaveteliPro::RequestSummary.create_or_update_from(
          FactoryGirl.create(:embargo_expiring_request, user: user)
        )
      end

      it 'counts the expiring embargoes' do
        expect(user.phase_count('embargo_expiring')).to eq 1
      end

      it 'includes the expiring embargo request in the phase total' do
        expect(user.phase_count('awaiting_response')).to eq 3
      end

      it 'does not double count the expiring embargo in the not_drafts total' do
        expect(user.phase_count('not_drafts')).to eq 4
      end

    end

  end

end
