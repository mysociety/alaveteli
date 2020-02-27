# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe InfoRequest::State do

  describe :all do

    it 'includes "waiting_response"' do
      expect(InfoRequest::State.all.include?("waiting_response")).
        to be true
    end

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
      expect(InfoRequest::State.phases.include?(name: _('Complete'),
                                                scope: :complete))
    end

  end

  describe :short_description do

    it 'returns a short description for a valid state' do
      expect(InfoRequest::State.short_description('attention_requested')).
        to eq 'Reported'
    end

    it 'raises an error for an unknown state' do
      expect { InfoRequest::State.short_description('meow') }.
        to raise_error 'unknown status meow'
    end

    context 'when a theme is in use' do

      before do
        InfoRequest.send(:require, File.expand_path(File.dirname(__FILE__) + '/../customstates'))
        InfoRequest.send(:include, InfoRequestCustomStates)
        InfoRequest.class_eval('@@custom_states_loaded = true')
      end

      it 'returns a short description for a theme state' do
        expect(InfoRequest::State.short_description('deadline_extended')).
          to eq 'Deadline extended'
      end

      it 'raises an error for an unknown state' do
        expect { InfoRequest::State.short_description('meow') }.
          to raise_error 'unknown status meow'
      end

    end

  end

  describe :phase_params do

    it 'returns hyphenised versions of the phases' do
      expect(InfoRequest::State.phase_params).
        to eq(awaiting_response: "awaiting-response",
              overdue: "overdue",
              very_overdue: "very-overdue",
              response_received: "response-received",
              clarification_needed: "clarification-needed",
              complete: "complete",
              other: "other")
    end
  end

end
