##
# Controller to render admin stats
#
class Admin::StatisticsController < AdminController
  def index
    @public_body_count = PublicBody.count

    @info_request_count = InfoRequest.count
    @outgoing_message_count = OutgoingMessage.count
    @incoming_message_count = IncomingMessage.count

    @user_count = User.count
    @track_thing_count = TrackThing.count

    @comment_count = Comment.count
    @request_by_state = InfoRequest.group('described_state').count
    @tracks_by_type = TrackThing.group('track_type').count
  end
end
