require 'spec_helper'

RSpec.describe InfoRequest::State do
  describe :all do
    it 'includes "waiting_response"' do
      expect(InfoRequest::State.all.include?("waiting_response"))
        .to be true
    end
  end

  describe '.unhappy' do
    subject { described_class.unhappy }

    let(:unhappy_states) do
      %w(partially_successful rejected waiting_response_very_overdue)
    end

    it { is_expected.to match_array(unhappy_states) }
  end

  describe '.valid?' do
    subject { described_class.valid?(state) }

    context 'with a state included in .all' do
      let(:state) { 'waiting_response' }
      it { is_expected.to eq(true) }
    end

    context 'with a state not included in .all' do
      let(:state) { 'invalid_state' }
      it { is_expected.to eq(false) }
    end
  end

  describe :phases do
    it 'returns an array' do
      expect(InfoRequest::State.phases).to be_a Array
    end

    it 'includes a hash with name "Complete" and scope :complete' do
      expect(InfoRequest::State.phases.include?({ name: _('Complete'),
                                                  scope: :complete }))
    end
  end

  describe :short_description do
    it 'returns a short description for a valid state' do
      expect(InfoRequest::State.short_description('attention_requested'))
        .to eq 'Reported'
    end

    it 'raises an error for an unknown state' do
      expect { InfoRequest::State.short_description('meow') }
        .to raise_error 'unknown status meow'
    end

    context 'when a theme is in use' do
      before do
        InfoRequest.send(:require, 'models/customstates')
        InfoRequest.send(:include, InfoRequestCustomStates)
        InfoRequest.class_eval('@@custom_states_loaded = true')
      end

      it 'returns a short description for a theme state' do
        expect(InfoRequest::State.short_description('deadline_extended'))
          .to eq 'Deadline extended'
      end

      it 'raises an error for an unknown state' do
        expect { InfoRequest::State.short_description('meow') }
          .to raise_error 'unknown status meow'
      end
    end
  end

  describe :phase_params do
    it 'returns hyphenised versions of the phases' do
      expect(InfoRequest::State.phase_params)
        .to eq({ awaiting_response: "awaiting-response",
                 overdue: "overdue",
                 very_overdue: "very-overdue",
                 response_received: "response-received",
                 clarification_needed: "clarification-needed",
                 complete: "complete",
                 other: "other" })
    end
  end

  describe '.roles' do
    it 'classifies core described states' do
      expect(InfoRequest::State.role_for('waiting_response')).to eq(:process)
      expect(InfoRequest::State.role_for('error_message')).to eq(:platform)
      expect(InfoRequest::State.role_for('vexatious')).to eq(:admin)
    end

    it 'classifies calculated-only statuses' do
      expect(InfoRequest::State.role_for('waiting_response_overdue'))
        .to eq(:calculated)
      expect(InfoRequest::State.role_for('waiting_classification'))
        .to eq(:calculated)
    end

    it 'returns nil for unknown states' do
      expect(InfoRequest::State.role_for('not_a_real_state')).to be_nil
    end
  end
end
