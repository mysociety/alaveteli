require 'spec_helper'

RSpec.describe User::Wall do
  describe '#events' do
    subject(:events) { described_class.new(user, limit: 2).events }

    let(:user) { FactoryBot.create(:user) }

    it 'includes the latest event on each request the user made' do
      info_request = FactoryBot.create(:info_request, user: user)
      sent = info_request.last_event_forming_initial_request
      comment = FactoryBot.create(:comment, info_request: info_request)
      commented = info_request.log_event('comment', comment_id: comment.id)

      expect(events).to include(commented)
      expect(events).not_to include(sent)
    end

    it 'includes the comments the user wrote' do
      comment = FactoryBot.create(:comment, user: user)
      event = comment.info_request.
        log_event('comment', comment_id: comment.id)

      expect(events).to eq([event])
    end

    it 'excludes events on hidden requests' do
      FactoryBot.create(:info_request, user: user, prominence: 'hidden')

      expect(events).to be_empty
    end

    it 'limits the newest request events' do
      FactoryBot.create(:info_request, user: user)
      newer = FactoryBot.create_list(:info_request, 2, user: user)

      expect(events.map(&:info_request)).to match_array(newer)
    end
  end
end
