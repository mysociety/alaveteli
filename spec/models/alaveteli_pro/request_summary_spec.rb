require 'spec_helper'

RSpec.describe AlaveteliPro::RequestSummary, type: :model do
  it "can belong to an info_request" do
    info_request = FactoryGirl.create(:info_request)
    summary = FactoryGirl.create(:request_summary, summarisable: info_request)
    expect(summary.summarisable).to eq info_request
    expect(info_request.request_summary).to eq summary
  end

  it "can belong to a draft_info_request" do
    draft = FactoryGirl.create(:draft_info_request)
    summary = FactoryGirl.create(:request_summary, summarisable: draft)
    expect(summary.summarisable).to eq draft
    expect(draft.request_summary).to eq summary
  end

  it "can belong to an info_request_batch" do
    batch = FactoryGirl.create(:info_request_batch)
    summary = FactoryGirl.create(:request_summary, summarisable: batch)
    expect(summary.summarisable).to eq batch
    expect(batch.request_summary).to eq summary
  end

  it "can belong to a draft_info_request_batch" do
    draft = FactoryGirl.create(:draft_info_request_batch)
    summary = FactoryGirl.create(:request_summary, summarisable: draft)
    expect(summary.summarisable).to eq draft
    expect(draft.request_summary).to eq summary
  end
end
