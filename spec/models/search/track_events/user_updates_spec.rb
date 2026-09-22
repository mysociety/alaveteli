require 'spec_helper'

RSpec.describe Search::TrackEvents::UserUpdates do
  let(:tracked_user) { FactoryBot.create(:user) }
  let(:track_thing) do
    FactoryBot.create(:user_track, tracked_user: tracked_user)
  end
  let(:their_request) do
    FactoryBot.create(:info_request, user: tracked_user)
  end

  subject(:events) do
    described_class.new(track_thing, sort_by: 'created_at', limit: 100).events
  end

  it 'finds requests the user sent' do
    is_expected.to include(
      FactoryBot.create(:sent_event, info_request: their_request)
    )
  end

  it 'finds responses to the user' do
    is_expected.to include(
      FactoryBot.create(:response_event, info_request: their_request)
    )
  end

  # requested_by: is indexed from the request owner, so it catches comments
  # left on their requests by anyone.
  it 'finds other people annotating their requests' do
    comment = FactoryBot.create(
      :comment_event,
      info_request: their_request,
      comment: FactoryBot.create(:visible_comment, info_request: their_request)
    )
    is_expected.to include(comment)
  end

  # The other half of the query, commented_by:, has a stray space that stops
  # it matching anything. Following it here would add alerts, not port them.
  it 'ignores them annotating somebody else request' do
    comment = FactoryBot.create(
      :comment_event, comment: FactoryBot.create(:visible_comment,
                                                 user: tracked_user)
    )
    is_expected.not_to include(comment)
  end

  it 'ignores requests by anybody else' do
    is_expected.not_to include(FactoryBot.create(:sent_event))
  end
end
