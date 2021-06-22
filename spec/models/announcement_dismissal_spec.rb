# == Schema Information
# Schema version: 20210114161442
#
# Table name: announcement_dismissals
#
#  id              :integer          not null, primary key
#  announcement_id :integer          not null
#  user_id         :integer          not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

require 'spec_helper'

describe AnnouncementDismissal do
  it 'requires a announcement' do
    dismissal = FactoryBot.build(:announcement_dismissal, announcement: nil)
    expect(dismissal).not_to be_valid
  end

  it 'requires a user' do
    dismissal = FactoryBot.build(:announcement_dismissal, user: nil)
    expect(dismissal).not_to be_valid
  end
end
