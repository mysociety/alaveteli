require "spec_helper"

describe AlaveteliPro::RequestSummaryCategory do
  # The callbacks which create and update summaries interfere with our testing
  # so we skip them just for these tests
  before :all do
    InfoRequest.skip_callback(:save, :after, :create_or_update_request_summary)
  end

  after :all do
    InfoRequest.set_callback(:save, :after, :create_or_update_request_summary)
  end

  it "can belong to multiple request_summaries" do
    category = FactoryGirl.create(:request_summary_category)
    summary_1 = FactoryGirl.create(:request_summary,
                                   request_summary_categories: [category])
    summary_2 = FactoryGirl.create(:request_summary,
                                   request_summary_categories: [category])
    expect(category.request_summaries).
      to match_array([summary_1, summary_2])
  end

  describe "#draft" do
    it "returns the draft category" do
      expect(described_class.draft.slug).to eq "draft"
    end
  end

  describe "#complete" do
    it "returns the complete category" do
      expect(described_class.complete.slug).to eq "complete"
    end
  end

  describe "#clarification_needed" do
    it "returns the clarification_needed category" do
      expect(described_class.clarification_needed.slug).to eq "clarification_needed"
    end
  end

  describe "#awaiting_response" do
    it "returns the awaiting_response category" do
      expect(described_class.awaiting_response.slug).to eq "awaiting_response"
    end
  end

  describe "#response_received" do
    it "returns the response_received category" do
      expect(described_class.response_received.slug).to eq "response_received"
    end
  end

  describe "#overdue" do
    it "returns the overdue category" do
      expect(described_class.overdue.slug).to eq "overdue"
    end
  end

  describe "#very_overdue" do
    it "returns the very_overdue category" do
      expect(described_class.very_overdue.slug).to eq "very_overdue"
    end
  end

  describe "#other" do
    it "returns the other category" do
      expect(described_class.other.slug).to eq "other"
    end
  end

  describe "#embargo_expiring" do
    it "returns the embargo_expiring category" do
      expect(described_class.embargo_expiring.slug).to eq "embargo_expiring"
    end
  end

end
