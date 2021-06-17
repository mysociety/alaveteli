# -*- encoding : utf-8 -*-
# == Schema Information
# Schema version: 20210114161442
#
# Table name: draft_info_request_batches
#
#  id               :integer          not null, primary key
#  title            :string
#  body             :text
#  user_id          :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  embargo_duration :string
#

require 'spec_helper'

describe AlaveteliPro::DraftInfoRequestBatch do
  let(:draft_batch) { FactoryBot.create(:draft_info_request_batch) }
  let(:pro_user) { FactoryBot.create(:pro_user) }

  it "requires a user" do
    draft_batch.user = nil
    expect(draft_batch).not_to be_valid
  end

  it "sets a default body if none is provided" do
    draft = AlaveteliPro::DraftInfoRequestBatch.new(user: pro_user)
    expect(draft.body).to eq "Dear [Authority name],\n\n\n\nYours faithfully,\n\n#{pro_user.name}"
  end

  it "it imposes an alphabetical sort order on associated public bodies" do
    public_body1 = FactoryBot.create(:public_body, :name => "Body 1")
    public_body2 = FactoryBot.create(:public_body, :name => "A Public Body")
    draft = FactoryBot.create(:draft_info_request_batch,
                              :public_bodies => [public_body1, public_body2],
                              :user => pro_user)
    draft.reload
    expect(draft.public_bodies).to eq ([public_body2, public_body1])
  end

  it_behaves_like "RequestSummaries"
end
