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
require 'models/concerns/info_request/draft_title_validation'

RSpec.describe DraftInfoRequest do
  it_behaves_like 'RequestSummaries'
  it_behaves_like 'concerns/info_request/draft_title_validation',
                  FactoryBot.build(:draft_info_request)

  describe '#valid?' do
    subject { record.valid? }

    context 'without a user' do
      let(:record) { described_class.new(user: nil) }
      it { is_expected.to eq(false) }
    end

    context 'with a user' do
      let(:record) { FactoryBot.build(:draft_info_request, user: user) }
      let(:user) { FactoryBot.build(:user) }
      it { is_expected.to eq(true) }
    end
  end
end
