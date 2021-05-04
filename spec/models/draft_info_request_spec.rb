# == Schema Information
# Schema version: 20210114161442
#
# Table name: draft_info_requests
#
#  id               :integer          not null, primary key
#  title            :string
#  user_id          :integer
#  public_body_id   :integer
#  body             :text
#  embargo_duration :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

require 'spec_helper'

describe DraftInfoRequest do
  let(:draft) { FactoryBot.create(:draft_info_request) }

  it "requires a user" do
    draft_request = DraftInfoRequest.new
    expect(draft_request.valid?).to be false
    draft_request.user = FactoryBot.create(:user)
    expect(draft_request.valid?).to be true
  end

  it_behaves_like "RequestSummaries"
end
