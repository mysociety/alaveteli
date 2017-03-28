require 'spec_helper'

describe AlaveteliPro::DraftInfoRequestBatch do
  let(:draft_batch) { FactoryGirl.create(:draft_info_request_batch) }

  it "requires a user" do
    draft_batch.user = nil
    expect(draft_batch).not_to be_valid
  end
end
