require 'spec_helper'

RSpec.describe InfoRequest::State::Calculator do
  let(:info_request) { FactoryBot.create(:info_request) }
  let(:calculator) { described_class.new(info_request) }

  describe '#phase' do
    it 'returns :awaiting_response when the request is in state "waiting_response"' do
      expect(calculator.phase).to eq(:awaiting_response)
    end

    it 'returns :overdue when the request is in state "waiting_response_overdue"' do
      travel_to(info_request.date_response_required_by + 2.days) do
        expect(info_request.calculate_status).to eq "waiting_response_overdue"
        expect(calculator.phase).to eq(:overdue)
      end
    end

    it 'returns :very_overdue when the request is in state "waiting_response_very_overdue"' do
      travel_to(info_request.date_very_overdue_after + 2.days) do
        expect(info_request.calculate_status).to eq "waiting_response_very_overdue"
        expect(calculator.phase).to eq(:very_overdue)
      end
    end

    it 'returns :clarification_needed when the request is in state "waiting_clarification"' do
      info_request.set_described_state('waiting_clarification')
      expect(calculator.phase).to eq(:clarification_needed)
    end

    it 'returns :complete when the request is in state "not_held"' do
      info_request.set_described_state('not_held')
      expect(calculator.phase).to eq(:complete)
    end

    it 'returns :other when the request is in state "gone_postal"' do
      info_request.set_described_state('gone_postal')
      expect(calculator.phase).to eq(:other)
    end

    it 'returns :response_received when the request is awaiting description' do
      info_request.awaiting_description = true
      info_request.save
      expect(calculator.phase).to eq(:response_received)
    end

  end

  describe '#transitions' do
    context "when the request is in an admin state" do
      let(:empty_hash) do
        {
          pending: {},
          complete: {},
          other: {}
        }
      end

      let(:admin_states) { ['not_foi', 'vexatious'] }

      it "always returns an empty hash" do
        admin_states.each do |state|
          info_request.set_described_state(state)
          transitions = calculator.transitions(
            is_owning_user: true,
            user_asked_to_update_status: true)
          expect(transitions).to(eq(empty_hash))
        end
      end
    end

    shared_examples_for "#transitions for an owner" do |states|
      let(:expected_when_asked_to_update) do
        {
          pending:  {
            "waiting_response"      => "I'm still <strong>waiting</strong> for my information <small>(maybe you got an acknowledgement)</small>",
            "waiting_clarification" => "I've been asked to <strong>clarify</strong> my request",
            "internal_review"       => "I'm waiting for an <strong>internal review</strong> response",
            "gone_postal"           => "They are going to reply <strong>by postal mail</strong>"
          },
          complete: {
            "not_held"              => "They do <strong>not have</strong> the information <small>(maybe they say who does)</small>",
            "partially_successful"  => "I've received <strong>some of the information</strong>",
            "successful"            => "I've received <strong>all the information</strong>",
            "rejected"              => "My request has been <strong>refused</strong>"
          },
          other: {
            "error_message"         => "I've received an <strong>error message</strong>",
            "requires_admin"        => "This request <strong>requires administrator attention</strong>",
            "user_withdrawn"        => "I would like to <strong>withdraw this request</strong>"
          }
        }
      end

      let(:expected_when_not_asked_to_update) do
        {
          pending:  {
            "waiting_response"      => "I'm still <strong>waiting</strong> for my information <small>(maybe you got an acknowledgement)</small>",
            "waiting_clarification" => "I've been asked to <strong>clarify</strong> my request",
            "gone_postal"           => "They are going to reply <strong>by postal mail</strong>"
          },
          complete: {
            "not_held"              => "They do <strong>not have</strong> the information <small>(maybe they say who does)</small>",
            "partially_successful"  => "I've received <strong>some of the information</strong>",
            "successful"            => "I've received <strong>all the information</strong>",
            "rejected"              => "My request has been <strong>refused</strong>"
          },
          other: {
            "error_message"  => "I've received an <strong>error message</strong>",
          }
        }
      end
      states.each do |state|
        context "when a request is #{state}" do
          context "and the user has asked to updated the status" do
            it "returns a correctly labelled hash of all states" do
              info_request.set_described_state(state)
              transitions = calculator.transitions(
                is_owning_user: true,
                user_asked_to_update_status: true)
              expect(transitions).to eq expected_when_asked_to_update
            end
          end

          context "and the user has not asked to updated the status" do
            it "returns a correctly labelled hash of all states" do
              info_request.set_described_state(state)
              transitions = calculator.transitions(
                is_owning_user: true,
                user_asked_to_update_status: false)
              expect(transitions).to eq expected_when_not_asked_to_update
            end
          end
        end
      end
    end

    shared_examples "#transitions for some other user" do |states|
      let(:expected) do
        {
          pending:  {
            "waiting_response"      => "<strong>No response</strong> has been received <small>(maybe there's just an acknowledgement)</small>",
            "waiting_clarification" => "<strong>Clarification</strong> has been requested",
            "gone_postal"           => "A response will be sent <strong>by postal mail</strong>"
          },
          complete: {
            "not_held"              => "The authority do <strong>not have</strong> the information <small>(maybe they say who does)</small>",
            "partially_successful"  => "<strong>Some of the information</strong> has been sent ",
            "successful"            => "<strong>All the information</strong> has been sent",
            "rejected"              => "The request has been <strong>refused</strong>"
          },
          other: {
            "error_message"  => "An <strong>error message</strong> has been received"
          }
        }
      end
      states.each do |state|
        context "when a request is #{state}" do
          it "returns a correctly labelled hash of all the states" do
            info_request.set_described_state(state)
            transitions = calculator.transitions(
              is_owning_user: false,
              user_asked_to_update_status: false)
            expect(transitions).to eq expected
          end
        end
      end
    end

    context "when the request is pending" do
      context "and the user is the owner" do
        it_behaves_like(
          "#transitions for an owner",
          ['waiting_response', 'waiting_clarification', 'gone_postal'])
      end

      context "and the user is some other user" do
        it_behaves_like(
          "#transitions for some other user",
          ['waiting_response', 'waiting_clarification', 'gone_postal'])
      end
    end

    context "when the request is complete" do
      context "and the user is the owner" do
        it_behaves_like(
          "#transitions for an owner",
          ['not_held', 'partially_successful', 'successful', 'rejected'])
      end

      context "and the user is some other user" do
        it_behaves_like(
          "#transitions for some other user",
          ['not_held', 'partially_successful', 'successful', 'rejected'])
      end
    end

    context "when the request is in internal_review" do
      before :each do
        info_request.set_described_state("internal_review")
      end

      context "and the user is the owner" do
        it "returns only two pending states" do
          transitions = calculator.transitions(
            is_owning_user: true,
            user_asked_to_update_status: false)
          expected = ["internal_review", "gone_postal"]
          expect(transitions[:pending].keys).to eq(expected)
        end

        it "returns a different label for the internal_review status" do
          transitions = calculator.transitions(
            is_owning_user: true,
            user_asked_to_update_status: false)
          expected = "I'm still <strong>waiting</strong> for the internal review"
          expect(transitions[:pending]["internal_review"]).to eq expected
        end
      end

      context "and the user is some other user" do
        it "returns only two pending states" do
          transitions = calculator.transitions(
            is_owning_user: false,
            user_asked_to_update_status: false)
          expected = ["internal_review", "gone_postal"]
          expect(transitions[:pending].keys).to eq(expected)
        end

        it "returns a different label for the internal_review status" do
          transitions = calculator.transitions(
            is_owning_user: false,
            user_asked_to_update_status: false)
          expected = "Still awaiting an <strong>internal review</strong>"
          expect(transitions[:pending]["internal_review"]).to eq expected
        end
      end
    end

    context "when the request is in an 'other' state" do
      context "and the user is the owner" do
        it_behaves_like(
          "#transitions for an owner",
          ['waiting_response', 'waiting_clarification', 'gone_postal'])
      end

      context "and the user is some other user" do
        it_behaves_like(
          "#transitions for some other user",
          ['waiting_response', 'waiting_clarification', 'gone_postal'])
      end
    end
  end

  describe '#summarised_phase' do
    context "when the phase is :awaiting_response" do
      it "returns :in_progress" do
        allow(calculator).to receive(:phase).and_return(:awaiting_response)
        expect(calculator.summarised_phase).to eq :in_progress
      end
    end

    context "when the phase is :complete" do
      it "returns :complete" do
        allow(calculator).to receive(:phase).and_return(:complete)
        expect(calculator.summarised_phase).to eq :complete
      end
    end

    context "when the phase is :other" do
      it "returns :other" do
        allow(calculator).to receive(:phase).and_return(:other)
        expect(calculator.summarised_phase).to eq :other
      end
    end

    context "when the phase is :response_received, :clarification_needed,
             :overdue or :very_overdue" do
      it "returns :action_needed" do
        [
          :response_received,
          :clarification_needed,
          :overdue,
          :very_overdue
        ].each do |phase|
          allow(calculator).to receive(:phase).and_return(phase)
          expect(calculator.summarised_phase).to eq :action_needed
        end
      end
    end
  end
end
