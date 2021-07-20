# == Schema Information
# Schema version: 20210114161442
#
# Table name: request_summaries
#
#  id                 :integer          not null, primary key
#  title              :text
#  body               :text
#  public_body_names  :text
#  summarisable_type  :string           not null
#  summarisable_id    :integer          not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  user_id            :integer
#  request_created_at :datetime         not null
#  request_updated_at :datetime         not null
#

require 'spec_helper'

RSpec.describe AlaveteliPro::RequestSummary, type: :model do
  let(:public_bodies) { FactoryBot.create_list(:public_body, 3) }
  let(:public_body_names) do
    public_bodies.sort { |x,y| x.name <=> y.name }.map(&:name).join(" ")
  end

  it "requires a summarisable" do
    summary = FactoryBot.build(:request_summary, summarisable: nil)
    expect(summary).not_to be_valid
  end

  it "validates that the summarisable is unique" do
    summary = FactoryBot.create(:request_summary)
    # We specify fix_summarisable to be false so that the factory doesn't
    # try to sort out any duplication for us, as we explicitly want to test
    # this.
    summary_2 = FactoryBot.build(:request_summary,
                                 summarisable: summary.summarisable,
                                 fix_summarisable: false)
    expect(summary_2).not_to be_valid
  end

  it "does not require a user" do
    summary = FactoryBot.build(:request_summary, user: nil)
    expect(summary).to be_valid
  end

  describe ".create_or_update_from" do
    it "raises an ArgumentError if the request is of the wrong class" do
      event = FactoryBot.create(:info_request_event)
      expect { AlaveteliPro::RequestSummary.create_or_update_from(event) }.
        to raise_error(ArgumentError)
    end

    context "when the request already has a summary" do
      it "updates the existing summary from a request" do
        summary = FactoryBot.create(:request_summary)
        request = summary.summarisable
        public_body = FactoryBot.create(:public_body)
        request.title = "Updated title"
        request.public_body = public_body
        request.save!

        updated_summary = AlaveteliPro::RequestSummary.
          create_or_update_from(request)
        expect(updated_summary.id).to eq summary.id
        expect(updated_summary.title).to eq request.title
        expect(updated_summary.public_body_names).to eq public_body.name
        expect(updated_summary.summarisable).to eq request
        expect(updated_summary.user).to eq request.user
        expected_categories = [
          AlaveteliPro::RequestSummaryCategory.awaiting_response
        ]
        expect(updated_summary.request_summary_categories).
          to match_array expected_categories
        expect(updated_summary.request_created_at).
          to be_within(1.second).of(summary.summarisable.created_at)
        expect(updated_summary.request_updated_at).
          to be_within(1.second).of(summary.summarisable.updated_at)
      end

      it "updates the existing summary from a batch request" do
        batch = FactoryBot.create(
          :info_request_batch,
          public_bodies: public_bodies
        )
        summary = FactoryBot.create(:request_summary, summarisable: batch)
        public_body = FactoryBot.create(:public_body)
        batch.title = "Updated title"
        batch.body = "Updated body"
        batch.public_bodies << public_body
        batch.save
        updated_summary = AlaveteliPro::RequestSummary.
          create_or_update_from(batch)
        expect(updated_summary.id).to eq summary.id
        expect(updated_summary.title).to eq batch.title
        expect(updated_summary.body).to eq batch.body
        expect(updated_summary.public_body_names).
          to match /.*#{public_body.name}.*/
        expect(updated_summary.summarisable).to eq batch
        expect(updated_summary.user).to eq batch.user
        expected_categories = [
          AlaveteliPro::RequestSummaryCategory.awaiting_response
        ]
        expect(updated_summary.request_summary_categories).
          to match_array expected_categories
        expect(updated_summary.request_created_at).
          to be_within(1.second).of(summary.summarisable.created_at)
        expect(updated_summary.request_updated_at).
          to be_within(1.second).of(summary.summarisable.updated_at)
      end
    end

    context "when the request doesn't already have a summary" do
      it "creates a summary from an info_request" do
        request = FactoryBot.create(:info_request)
        summary = AlaveteliPro::RequestSummary.
          create_or_update_from(request)
        expect(summary.title).to eq request.title
        expect(summary.body).to eq request.outgoing_messages.first.body
        expect(summary.public_body_names).to eq request.public_body.name
        expect(summary.summarisable).to eq request
        expect(summary.user).to eq request.user
        expected_categories = [
          AlaveteliPro::RequestSummaryCategory.awaiting_response
        ]
        expect(summary.request_summary_categories).
          to match_array expected_categories
        expect(summary.request_created_at).
          to be_within(1.second).of(request.created_at)
        expect(summary.request_updated_at).
          to be_within(1.second).of(request.updated_at)
      end

      it "creates a summary from a draft_info_request" do
        draft = FactoryBot.create(:draft_info_request)
        summary = AlaveteliPro::RequestSummary.create_or_update_from(draft)
        expect(summary.title).to eq draft.title
        expect(summary.body).to eq draft.body
        expect(summary.public_body_names).to eq draft.public_body.name
        expect(summary.summarisable).to eq draft
        expect(summary.user).to eq draft.user
        expected_categories = [
          AlaveteliPro::RequestSummaryCategory.draft
        ]
        expect(summary.request_summary_categories).
          to match_array expected_categories
        expect(summary.request_created_at).
          to be_within(1.second).of(draft.created_at)
        expect(summary.request_updated_at).
          to be_within(1.second).of(draft.updated_at)
      end

      it "creates a summary from an info_request_batch" do
        batch = FactoryBot.create(
          :info_request_batch,
          public_bodies: public_bodies
        )
        summary = AlaveteliPro::RequestSummary.create_or_update_from(batch)
        expect(summary.title).to eq batch.title
        expect(summary.body).to eq batch.body
        expect(summary.public_body_names).to eq public_body_names
        expect(summary.summarisable).to eq batch
        expect(summary.user).to eq batch.user
        expected_categories = [
          AlaveteliPro::RequestSummaryCategory.awaiting_response
        ]
        expect(summary.request_summary_categories).
          to match_array expected_categories
        expect(summary.request_created_at).
          to be_within(1.second).of(batch.created_at)
        expect(summary.request_updated_at).
          to be_within(1.second).of(batch.updated_at)
      end

      it "creates a summary from an draft_info_request_batch" do
        draft = FactoryBot.create(
          :draft_info_request_batch,
          public_bodies: public_bodies
        )
        summary = AlaveteliPro::RequestSummary.create_or_update_from(draft)
        expect(summary.title).to eq draft.title
        expect(summary.body).to eq draft.body
        expect(summary.public_body_names).to eq public_body_names
        expect(summary.summarisable).to eq draft
        expect(summary.user).to eq draft.user
        expected_categories = [AlaveteliPro::RequestSummaryCategory.draft]
        expect(summary.request_summary_categories).
          to match_array expected_categories
        expect(summary.request_created_at).
          to be_within(1.second).of(draft.created_at)
        expect(summary.request_updated_at).
          to be_within(1.second).of(draft.updated_at)
      end
    end

    describe "setting public body names" do
      context "when the request is a draft with no public body" do
        let(:draft) do
          FactoryBot.create(:draft_info_request, public_body: nil)
        end
        let(:summary) do
          AlaveteliPro::RequestSummary.create_or_update_from(draft)
        end

        it "sets the public body names to nil" do
          expect(summary.public_body_names).to be_nil
        end
      end
    end


    describe "setting categories" do
      context "when the request is a draft request" do
        let(:draft) { FactoryBot.create(:draft_info_request) }
        let(:summary) do
          AlaveteliPro::RequestSummary.create_or_update_from(draft)
        end

        it "adds the draft category" do
          expected_categories = [AlaveteliPro::RequestSummaryCategory.draft]
          expect(summary.request_summary_categories).
            to match_array expected_categories
        end
      end

      context "when the request is a draft batch request" do
        it "adds the draft category" do
          draft = FactoryBot.create(
            :draft_info_request_batch,
            public_bodies: public_bodies
          )
          summary = AlaveteliPro::RequestSummary.
            create_or_update_from(draft)
          expected_categories = [AlaveteliPro::RequestSummaryCategory.draft]
          expect(summary.request_summary_categories).
            to match_array expected_categories
        end
      end

      context "when the request has an expiring embargo" do
        let(:request) { FactoryBot.create(:embargo_expiring_request) }
        let(:summary) do
          summary = AlaveteliPro::RequestSummary.
            create_or_update_from(request)
        end

        it "adds the embargo_expiring category" do
          expected_categories = [
            AlaveteliPro::RequestSummaryCategory.embargo_expiring,
            AlaveteliPro::RequestSummaryCategory.awaiting_response
          ]
          expect(summary.request_summary_categories).
            to match_array expected_categories
        end
      end

      context "when the request is a batch with expiring embargoes" do
        let(:batch) do
          FactoryBot.create(:info_request_batch,
                            public_bodies: public_bodies)
        end
        let(:summary) do
          AlaveteliPro::RequestSummary.create_or_update_from(batch)
        end

        before do
          batch.create_batch!
          batch.info_requests.each do |request|
            FactoryBot.create(:expiring_embargo, info_request: request)
          end
          batch.reload
        end

        it "adds the embargo_expiring category" do
          expected_categories = [
            AlaveteliPro::RequestSummaryCategory.embargo_expiring,
            AlaveteliPro::RequestSummaryCategory.awaiting_response
          ]
          expect(summary.request_summary_categories).
            to match_array expected_categories
        end
      end

      context "when the request is an InfoRequest" do
        let(:request) { FactoryBot.create(:info_request) }
        let(:summary) do
          AlaveteliPro::RequestSummary.create_or_update_from(request)
        end

        it "adds the phase as a category" do
          expected_categories = [
            AlaveteliPro::RequestSummaryCategory.awaiting_response
          ]
          expect(summary.request_summary_categories).
            to match_array expected_categories
        end
      end

      context "when the request is an InfoRequestBatch" do
        let(:public_bodies) { FactoryBot.create_list(:public_body, 5) }
        let(:batch) do
          FactoryBot.create(:info_request_batch,
                            public_bodies: public_bodies)
        end
        let(:summary) do
          AlaveteliPro::RequestSummary.create_or_update_from(batch)
        end

        before do
          batch.create_batch!
          # Because the batch request creates each request in a transaction,
          # we need to reload it to make sure we have all the requests
          batch.reload

          first_request = batch.info_requests.first
          incoming_message = FactoryBot.create(
            :incoming_message,
            info_request: first_request)
          first_request.log_event(
            "response",
            incoming_message_id: incoming_message.id)
          first_request.awaiting_description = true
          first_request.save!

          second_request = batch.info_requests.second
          incoming_message = FactoryBot.create(
            :incoming_message,
            info_request: second_request)
          second_request.set_described_state('successful')

          batch.reload
        end

        it "adds all the batch's requests unique phases as categories" do
          skip 'Frequent transient failures'
          # There are 5 requests, but three should be in "awaiting_response"
          # and they should be de-duped
          expected_categories = [
            AlaveteliPro::RequestSummaryCategory.awaiting_response,
            AlaveteliPro::RequestSummaryCategory.response_received,
            AlaveteliPro::RequestSummaryCategory.complete
          ]
          expect(summary.request_summary_categories).
            to match_array expected_categories
        end
      end
    end
  end

  describe ".category" do
    it "returns summaries with the appropriate category" do
      draft = AlaveteliPro::RequestSummaryCategory.draft
      awaiting_response = AlaveteliPro::RequestSummaryCategory.
        awaiting_response
      draft_summary = FactoryBot.create(
        :request_summary,
        request_summary_categories: [draft]
      )
      awaiting_summary = FactoryBot.create(
        :request_summary,
        request_summary_categories: [awaiting_response]
      )
      expect(AlaveteliPro::RequestSummary.category(:draft)).
        to match_array [draft_summary]
      expect(AlaveteliPro::RequestSummary.category(:awaiting_response)).
        to match_array [awaiting_summary]
    end
  end

  describe ".not_category" do
    it "returns summaries with the appropriate category" do
      # Make sure there aren't any random other request summaries around from
      # fixtures etc
      AlaveteliPro::RequestSummary.destroy_all
      draft = AlaveteliPro::RequestSummaryCategory.draft
      awaiting_response = AlaveteliPro::RequestSummaryCategory.
        awaiting_response
      complete = AlaveteliPro::RequestSummaryCategory.complete
      embargo_expiring = AlaveteliPro::RequestSummaryCategory.
        embargo_expiring
      draft_summary = FactoryBot.create(
        :request_summary,
        request_summary_categories: [draft]
      )
      awaiting_summary = FactoryBot.create(
        :request_summary,
        request_summary_categories: [awaiting_response]
      )
      complete_summary = FactoryBot.create(
        :request_summary,
        request_summary_categories: [complete]
      )
      expiring_summary = FactoryBot.create(
        :request_summary,
        request_summary_categories: [complete, embargo_expiring]
      )
      expect(AlaveteliPro::RequestSummary.not_category(:draft)).
        to match_array [awaiting_summary,
                        complete_summary,
                        expiring_summary]
      expect(AlaveteliPro::RequestSummary.not_category(:complete)).
        to match_array [awaiting_summary, draft_summary]
    end
  end
end
