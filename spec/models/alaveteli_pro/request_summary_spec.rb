require 'spec_helper'

RSpec.describe AlaveteliPro::RequestSummary, type: :model do

  let(:public_bodies) { FactoryGirl.create_list(:public_body, 3) }
  let(:public_body_names) { public_bodies.map(&:name).join(" ") }

  it "requires a summarisable" do
    summary = FactoryGirl.build(:request_summary, summarisable: nil)
    expect(summary).not_to be_valid
  end

  it "does not require a user" do
    # InfoRequest does not require a user, so we can't require one here either
    summary = FactoryGirl.build(:request_summary, user: nil)
    expect(summary).to be_valid
  end

  describe ".create_or_update_from" do
    # All these classes create and update summaries of themselves during an
    # after_save callback. That makes testing this method explicitly hard, so
    # we skip the callback for the duration of these tests.
    before :all do
      InfoRequest.skip_callback(:save, :after, :create_or_update_request_summary)
      DraftInfoRequest.skip_callback(:save, :after, :create_or_update_request_summary)
      InfoRequestBatch.skip_callback(:save, :after, :create_or_update_request_summary)
      AlaveteliPro::DraftInfoRequestBatch.skip_callback(:save, :after, :create_or_update_request_summary)
    end

    after :all do
      InfoRequest.set_callback(:save, :after, :create_or_update_request_summary)
      DraftInfoRequest.set_callback(:save, :after, :create_or_update_request_summary)
      InfoRequestBatch.set_callback(:save, :after, :create_or_update_request_summary)
      AlaveteliPro::DraftInfoRequestBatch.set_callback(:save, :after, :create_or_update_request_summary)
    end

    it "raises an ArgumentError if the request is of the wrong class" do
      event = FactoryGirl.create(:info_request_event)
      expect { AlaveteliPro::RequestSummary.create_or_update_from(event) }.
        to raise_error(ArgumentError)
    end

    context "when the request already has a summary" do
      it "updates the existing summary from a request" do
        summary = FactoryGirl.create(:request_summary)
        request = summary.summarisable
        public_body = FactoryGirl.create(:public_body)
        request.title = "Updated title"
        request.public_body = public_body
        request.save
        updated_summary = AlaveteliPro::RequestSummary.create_or_update_from(request)
        expect(updated_summary.id).to eq summary.id
        expect(updated_summary.title).to eq request.title
        expect(updated_summary.public_body_names).to eq public_body.name
        expect(updated_summary.summarisable).to eq request
        expect(updated_summary.user).to eq request.user
        expect(updated_summary.request_summary_categories).to match_array []
      end

      it "updates the existing summary from a batch request" do
        batch = FactoryGirl.create(
          :info_request_batch,
          public_bodies: public_bodies
        )
        summary = FactoryGirl.create(:request_summary, summarisable: batch)
        public_body = FactoryGirl.create(:public_body)
        batch.title = "Updated title"
        batch.body = "Updated body"
        batch.public_bodies << public_body
        batch.save
        updated_summary = AlaveteliPro::RequestSummary.create_or_update_from(batch)
        expect(updated_summary.id).to eq summary.id
        expect(updated_summary.title).to eq batch.title
        expect(updated_summary.body).to eq batch.body
        expect(updated_summary.public_body_names).to match /.*#{public_body.name}.*/
        expect(updated_summary.summarisable).to eq batch
        expect(updated_summary.user).to eq batch.user
        expect(updated_summary.request_summary_categories).to match_array []
      end
    end

    context "when the request doesn't already have a summary" do
      it "creates a summary from an info_request" do
        request = FactoryGirl.create(:info_request)
        summary = AlaveteliPro::RequestSummary.create_or_update_from(request)
        expect(summary.title).to eq request.title
        expect(summary.body).to eq request.outgoing_messages.first.body
        expect(summary.public_body_names).to eq request.public_body.name
        expect(summary.summarisable).to eq request
        expect(summary.user).to eq request.user
        expect(summary.request_summary_categories).to match_array []
      end

      it "creates a summary from a draft_info_request" do
        draft = FactoryGirl.create(:draft_info_request)
        summary = AlaveteliPro::RequestSummary.create_or_update_from(draft)
        expect(summary.title).to eq draft.title
        expect(summary.body).to eq draft.body
        expect(summary.public_body_names).to eq draft.public_body.name
        expect(summary.summarisable).to eq draft
        expect(summary.user).to eq draft.user
        expected_categories = [AlaveteliPro::RequestSummaryCategory.draft]
        expect(summary.request_summary_categories).
          to match_array expected_categories
      end

      it "creates a summary from an info_request_batch" do
        batch = FactoryGirl.create(
          :info_request_batch,
          public_bodies: public_bodies
        )
        summary = AlaveteliPro::RequestSummary.create_or_update_from(batch)
        expect(summary.title).to eq batch.title
        expect(summary.body).to eq batch.body
        expect(summary.public_body_names).to eq public_body_names
        expect(summary.summarisable).to eq batch
        expect(summary.user).to eq batch.user
        expect(summary.request_summary_categories).to match_array []
      end

      it "creates a summary from an draft_info_request_batch" do
        draft = FactoryGirl.create(
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
      end
    end

    describe "setting public body names" do
      context "when the request is a draft with no public body" do
        let(:draft) do
          FactoryGirl.create(:draft_info_request, public_body: nil)
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
        let(:draft) { FactoryGirl.create(:draft_info_request) }
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
          draft = FactoryGirl.create(
            :draft_info_request_batch,
            public_bodies: public_bodies
          )
          summary = AlaveteliPro::RequestSummary.create_or_update_from(draft)
          expected_categories = [AlaveteliPro::RequestSummaryCategory.draft]
          expect(summary.request_summary_categories).
            to match_array expected_categories
        end
      end

      context "when the request has an expiring embargo" do
        let(:request) { FactoryGirl.create(:embargo_expiring_request) }
        let(:summary) do
          summary = AlaveteliPro::RequestSummary.create_or_update_from(request)
        end

        it "adds the embargo_expiring category" do
          expected_categories = [AlaveteliPro::RequestSummaryCategory.embargo_expiring]
          expect(summary.request_summary_categories).
            to match_array expected_categories
        end
      end

      context "when the request is a batch with expiring embargoes" do
        let(:batch) do
          FactoryGirl.create(:info_request_batch, public_bodies: public_bodies)
        end
        let(:summary) do
          AlaveteliPro::RequestSummary.create_or_update_from(batch)
        end

        before do
          batch.create_batch!
          batch.info_requests.each do |request|
            FactoryGirl.create(:expiring_embargo, info_request: request)
          end
          batch.reload
        end

        it "adds the embargo_expiring category" do
          expected_categories = [AlaveteliPro::RequestSummaryCategory.embargo_expiring]
          expect(summary.request_summary_categories).
            to match_array expected_categories
        end
      end
    end
  end
end
