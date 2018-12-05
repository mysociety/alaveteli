require 'spec_helper'

describe InfoRequest::State::UpdatedBeforeQuery do

  describe '#call' do
    subject { described_class.new(timestamp: cutoff_date).call }
    let(:cutoff_date) { 20.days.ago }
    let(:info_request) { FactoryBot.create(:info_request) }

    context 'includes requests created before the cutoff date' do
      before { time_travel_to(Time.zone.now - 21.days) { info_request } }

      it { is_expected.to include(info_request) }
    end

    context 'excludes requests created after the cutoff date' do
      it { is_expected.to_not include(info_request) }
    end

    context 'excludes requests updated after the cutoff date' do
      before do
        time_travel_to(Time.zone.now - 21.days) { info_request }
        info_request.update_attribute(:updated_at, Time.zone.now)
      end

      it { is_expected.to_not include(info_request) }
    end

    context 'excludes requests with an outgoing_message created after the cutoff date' do
      before do
        time_travel_to(Time.zone.now - 21.days) { info_request }
        FactoryBot.create(:internal_review_request, info_request: info_request)
      end

      it { is_expected.to_not include(info_request) }
    end

    context 'includes requests with an outgoing_message created before the cutoff date' do
      before do
        time_travel_to(Time.zone.now - 21.days) do
          info_request
          FactoryBot.create(:internal_review_request,
                            info_request: info_request)
        end
      end

      it { is_expected.to include(info_request) }
    end

    # rare creatures but sometimes it happens
    context 'handles requests without an outgoing_message' do
      before do
        time_travel_to(Time.zone.now - 21.days) do
          info_request.outgoing_messages.first.destroy
        end
      end

      it { is_expected.to include(info_request) }
    end

  end
end
