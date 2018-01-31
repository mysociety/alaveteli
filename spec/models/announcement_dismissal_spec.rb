require 'spec_helper'

describe AnnouncementDismissal do
  it 'requires a announcement' do
    dismissal = FactoryGirl.build(:announcement_dismissal, announcement: nil)
    expect(dismissal).not_to be_valid
  end

  it 'requires a user' do
    dismissal = FactoryGirl.build(:announcement_dismissal, user: nil)
    expect(dismissal).not_to be_valid
  end
end
