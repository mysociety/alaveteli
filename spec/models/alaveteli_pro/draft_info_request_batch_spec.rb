# == Schema Information
#
# Table name: draft_info_request_batches
#
#  id               :integer          not null, primary key
#  title            :string(255)
#  body             :text
#  user_id          :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  embargo_duration :string(255)
#

require 'spec_helper'

describe AlaveteliPro::DraftInfoRequestBatch do
  let(:draft_batch) { FactoryGirl.create(:draft_info_request_batch) }

  it "requires a user" do
    draft_batch.user = nil
    expect(draft_batch).not_to be_valid
  end

  it "sets a default body if none is provided" do
    pro_user = FactoryGirl.create(:pro_user)
    draft = AlaveteliPro::DraftInfoRequestBatch.new(user: pro_user)
    expect(draft.body).to eq "Dear [Authority name],\n\n\n\nYours faithfully,\n\n#{pro_user.name}"
  end

  it_behaves_like "RequestSummaries"
end
