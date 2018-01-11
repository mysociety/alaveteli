# == Schema Information
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
  let(:draft) { FactoryGirl.create(:draft_info_request) }

  it "belongs to a public body" do
    expect(draft.public_body).to be_a(PublicBody)
  end

  it "belongs to a user" do
    expect(draft.user).to be_a(User)
  end

  it "has a title" do
    expect(draft.title).to be_a(String)
  end

  it "has a body" do
    expect(draft.body).to be_a(String)
  end

  it "requires a user" do
    draft_request = DraftInfoRequest.new
    expect(draft_request.valid?).to be false
    draft_request.user = FactoryGirl.create(:user)
    expect(draft_request.valid?).to be true
  end

  it_behaves_like "RequestSummaries"
end
