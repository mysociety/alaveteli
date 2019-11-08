# == Schema Information
# Schema version: 20220322100510
#
# Table name: announcement_dismissals
#
#  id              :bigint           not null, primary key
#  announcement_id :bigint           not null
#  user_id         :bigint           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

require 'spec_helper'

RSpec.describe AnnouncementDismissal do
  it 'requires a announcement' do
    dismissal = FactoryBot.build(:announcement_dismissal, announcement: nil)
    expect(dismissal).not_to be_valid
  end

  it 'requires a user' do
    dismissal = FactoryBot.build(:announcement_dismissal, user: nil)
    expect(dismissal).not_to be_valid
  end
end
