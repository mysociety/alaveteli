# -*- encoding : utf-8 -*-
require 'spec_helper'

describe InfoRequest::State::Transitions do
  let(:info_request) { FactoryBot.create(:info_request) }

  describe ".transition_label" do
    it "requires a to_state parameter" do
      expect { subject.transition_label }.to raise_error(ArgumentError)
    end

    it "requires an is_owning_user key in the options" do
      expect { subject.transition_label('successful', {}) }.to raise_error(KeyError)
    end

    context "when the to_state is waiting_response" do
      context "and is_owning_user is true" do
        it "returns the right label" do
          expected = "I'm still <strong>waiting</strong> for my information <small>(maybe you got an acknowledgement)</small>"
          actual = subject.transition_label("waiting_response", is_owning_user: true)
          expect(actual).to eq(expected)
        end
      end

      context "and is_owning_user is false" do
        it "returns the right label" do
          expected = "<strong>No response</strong> has been received <small>(maybe there's just an acknowledgement)</small>"
          actual = subject.transition_label("waiting_response", is_owning_user: false)
          expect(actual).to eq(expected)
        end
      end

      context "and is_pro_user is true" do
        it "returns the right label" do
          expected = "Awaiting response"
          actual = subject.transition_label("waiting_response", is_pro_user: true, is_owning_user: true)
          expect(actual).to eq(expected)
        end
      end
    end

    context "when the to_state is waiting_clarification" do
      context "and is_owning_user is true" do
        it "returns the right label" do
          expected = "I've been asked to <strong>clarify</strong> my request"
          actual = subject.transition_label("waiting_clarification", is_owning_user: true)
          expect(actual).to eq(expected)
        end
      end

      context "and is_owning_user is false" do
        it "returns the right label" do
          expected = "<strong>Clarification</strong> has been requested"
          actual = subject.transition_label("waiting_clarification", is_owning_user: false)
          expect(actual).to eq(expected)
        end
      end

      context "and is_pro_user is true" do
        it "returns the right label" do
          expected = "Awaiting clarification"
          actual = subject.transition_label("waiting_clarification", is_pro_user: true, is_owning_user: true)
          expect(actual).to eq(expected)
        end
      end
    end

    context "when the to_state is gone_postal" do
      context "and is_owning_user is true" do
        it "returns the right label" do
          expected = "They are going to reply <strong>by post</strong>"
          actual = subject.transition_label("gone_postal", is_owning_user: true)
          expect(actual).to eq(expected)
        end
      end

      context "and is_owning_user is false" do
        it "returns the right label" do
          expected = "A response will be sent <strong>by post</strong>"
          actual = subject.transition_label("gone_postal", is_owning_user: false)
          expect(actual).to eq(expected)
        end
      end

      context "and is_pro_user is true" do
        it "returns the right label" do
          expected = "Handled by post"
          actual = subject.transition_label("gone_postal", is_pro_user: true, is_owning_user: true)
          expect(actual).to eq(expected)
        end
      end
    end

    context "when the to_state is not_held" do
      context "and is_owning_user is true" do
        it "returns the right label" do
          expected = "They do <strong>not have</strong> the information <small>(maybe they say who does)</small>"
          actual = subject.transition_label("not_held", is_owning_user: true)
          expect(actual).to eq(expected)
        end
      end

      context "and is_owning_user is false" do
        it "returns the right label" do
          expected = "The authority do <strong>not have</strong> the information <small>(maybe they say who does)</small>"
          actual = subject.transition_label("not_held", is_owning_user: false)
          expect(actual).to eq(expected)
        end
      end

      context "and is_pro_user is true" do
        it "returns the right label" do
          expected = "Information not held"
          actual = subject.transition_label("not_held", is_pro_user: true, is_owning_user: true)
          expect(actual).to eq(expected)
        end
      end
    end

    context "when the to_state is rejected" do
      context "and is_owning_user is true" do
        it "returns the right label" do
          expected = "My request has been <strong>refused</strong>"
          actual = subject.transition_label("rejected", is_owning_user: true)
          expect(actual).to eq(expected)
        end
      end

      context "and is_owning_user is false" do
        it "returns the right label" do
          expected = "The request has been <strong>refused</strong>"
          actual = subject.transition_label("rejected", is_owning_user: false)
          expect(actual).to eq(expected)
        end
      end

      context "and is_pro_user is true" do
        it "returns the right label" do
          expected = "Refused"
          actual = subject.transition_label("rejected", is_pro_user: true, is_owning_user: true)
          expect(actual).to eq(expected)
        end
      end
    end

    context "when the to_state is successful" do
      context "and is_owning_user is true" do
        it "returns the right label" do
          expected = "I've received <strong>all the information</strong>"
          actual = subject.transition_label("successful", is_owning_user: true)
          expect(actual).to eq(expected)
        end
      end

      context "and is_owning_user is false" do
        it "returns the right label" do
          expected = "<strong>All the information</strong> has been sent"
          actual = subject.transition_label("successful", is_owning_user: false)
          expect(actual).to eq(expected)
        end
      end

      context "and is_pro_user is true" do
        it "returns the right label" do
          expected = "Successful"
          actual = subject.transition_label("successful", is_pro_user: true, is_owning_user: true)
          expect(actual).to eq(expected)
        end
      end
    end

    context "when the to_state is partially_successful" do
      context "and is_owning_user is true" do
        it "returns the right label" do
          expected = "I've received <strong>some of the information</strong>"
          actual = subject.transition_label("partially_successful", is_owning_user: true)
          expect(actual).to eq(expected)
        end
      end

      context "and is_owning_user is false" do
        it "returns the right label" do
          expected = "<strong>Some of the information</strong> has been sent "
          actual = subject.transition_label("partially_successful", is_owning_user: false)
          expect(actual).to eq(expected)
        end
      end

      context "and is_pro_user is true" do
        it "returns the right label" do
          expected = "Partially successful"
          actual = subject.transition_label("partially_successful", is_pro_user: true, is_owning_user: true)
          expect(actual).to eq(expected)
        end
      end
    end

    context "when the to_state is internal_review" do
      context "and is_owning_user is true" do
        context "and the current_state is internal_review" do
          it "returns the right label" do
            expected = "I'm still <strong>waiting</strong> for the internal review"
            actual = subject.transition_label("internal_review", is_owning_user: true, in_internal_review: true)
            expect(actual).to eq(expected)
          end
        end

        context "and the current_state is not internal_review" do
          it "returns the right label" do
            expected = "I'm waiting for an <strong>internal review</strong> response"
            actual = subject.transition_label("internal_review", is_owning_user: true, in_internal_review: false)
            expect(actual).to eq(expected)
          end
        end
      end

      context "and is_owning_user is false" do
        context "and the current_state is internal_review" do
          it "returns the right label" do
            expected = "Still awaiting an <strong>internal review</strong>"
            actual = subject.transition_label("internal_review", is_owning_user: false, in_internal_review: true)
            expect(actual).to eq(expected)
          end
        end

        context "and the current_state is not internal_review" do
          it "does not have a label" do
            expect do
              subject.transition_label("internal_review", is_owning_user: false, in_internal_review: false)
            end.to raise_error(RuntimeError)
          end
        end
      end

      context "and is_pro_user is true" do
        context "and the current_state is internal_review" do
          it "returns the right label" do
            expected = "Awaiting internal review"
            actual = subject.transition_label("internal_review", is_pro_user: true, is_owning_user: true, in_internal_review: true)
            expect(actual).to eq(expected)
          end
        end

        context "and the current_state is not internal_review" do
          it "returns the right label" do
            expected = "Awaiting internal review"
            actual = subject.transition_label("internal_review", is_pro_user: true, is_owning_user: true, in_internal_review: false)
            expect(actual).to eq(expected)
          end
        end
      end
    end

    context "when the to_state is error_message" do
      context "and is_owning_user is true" do
        it "returns the right label" do
          expected = "I've received an <strong>error message</strong>"
          actual = subject.transition_label("error_message", is_owning_user: true)
          expect(actual).to eq(expected)
        end
      end

      context "and is_owning_user is false" do
        it "returns the right label" do
          expected = "An <strong>error message</strong> has been received"
          actual = subject.transition_label("error_message", is_owning_user: false)
          expect(actual).to eq(expected)
        end
      end

      context "and is_pro_user is true" do
        it "returns the right label" do
          expected = "Delivery error"
          actual = subject.transition_label("error_message", is_pro_user: true, is_owning_user: true)
          expect(actual).to eq(expected)
        end
      end
    end

    context "when the to_state is requires_admin" do
      context "and is_owning_user is true" do
        it "returns the right label" do
          expected = "This request <strong>requires administrator attention</strong>"
          actual = subject.transition_label("requires_admin", is_owning_user: true)
          expect(actual).to eq(expected)
        end
      end

      context "and is_owning_user is false" do
        it "does not have a label" do
          expect do
            subject.transition_label("requires_admin", is_owning_user: false)
          end.to raise_error(RuntimeError)
        end
      end

      context "and is_pro_user is true" do
        it "returns the right label" do
          expected = "Requires admin attention"
          actual = subject.transition_label("requires_admin", is_pro_user: true, is_owning_user: true)
          expect(actual).to eq(expected)
        end
      end
    end

    context "when the to_state is user_withdrawn" do
      context "and is_owning_user is true" do
        it "returns the right label" do
          expected = "I would like to <strong>withdraw this request</strong>"
          actual = subject.transition_label("user_withdrawn", is_owning_user: true)
          expect(actual).to eq(expected)
        end
      end

      context "and is_owning_user is false" do
        it "does not have a label" do
          expect do
            subject.transition_label("requires_admin", is_owning_user: false)
          end.to raise_error(RuntimeError)
        end
      end

      context "and is_pro_user is true" do
        it "returns the right label" do
          expected = "Withdrawn"
          actual = subject.transition_label("user_withdrawn", is_pro_user: true, is_owning_user: true)
          expect(actual).to eq(expected)
        end
      end
    end

    context "when the to_state is attention_requested" do
      context "and is_owning_user is true" do
        it "does not have a label" do
          expect do
            subject.transition_label("attention_requested", is_owning_user: true)
          end.to raise_error(RuntimeError)
        end
      end

      context "and is_owning_user is false" do
        it "does not have a label" do
          expect do
            subject.transition_label("attention_requested", is_owning_user: false)
          end.to raise_error(RuntimeError)
        end
      end

      context "and is_pro_user is false" do
        it "does not have a label" do
          expect do
            subject.transition_label("attention_requested", is_pro_user: true, is_owning_user: true)
          end.to raise_error(RuntimeError)
        end
      end
    end

    context "when the to_state is vexatious" do
      context "and is_owning_user is true" do
        it "does not have a label" do
          expect do
            subject.transition_label("vexatious", is_owning_user: true)
          end.to raise_error(RuntimeError)
        end
      end

      context "and is_owning_user is false" do
        it "does not have a label" do
          expect do
            subject.transition_label("vexatious", is_owning_user: false)
          end.to raise_error(RuntimeError)
        end
      end

      context "and is_pro_user is false" do
        it "does not have a label" do
          expect do
            subject.transition_label("vexatious", is_pro_user: true, is_owning_user: true)
          end.to raise_error(RuntimeError)
        end
      end
    end

    context "when the to_state is not_foi" do
      context "and is_owning_user is true" do
        it "does not have a label" do
          expect do
            subject.transition_label("not_foi", is_owning_user: true)
          end.to raise_error(RuntimeError)
        end
      end

      context "and is_owning_user is false" do
        it "does not have a label" do
          expect do
            subject.transition_label("not_foi", is_owning_user: false)
          end.to raise_error(RuntimeError)
        end
      end

      context "and is_pro_user is false" do
        it "does not have a label" do
          expect do
            subject.transition_label("not_foi", is_pro_user: true, is_owning_user: true)
          end.to raise_error(RuntimeError)
        end
      end
    end
  end

  describe ".labelled_hash" do
    it "requires a states parameter" do
      expect { subject.labelled_hash }.to raise_error(ArgumentError)
    end

    it "requires an is_owning_user key in the options" do
      expect { subject.labelled_hash(['successful'], {}) }.to raise_error(KeyError)
    end

    it "returns a hash of labelled states" do
      actual = subject.labelled_hash(['successful'], {is_owning_user: true})
      expected = {"successful" => "I've received <strong>all the information</strong>"}
      expect(expected).to eq(actual)
    end
  end
end
