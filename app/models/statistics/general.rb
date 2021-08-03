module Statistics
  # High-level site statistics and version information
  class General
    def to_h
      {
        alaveteli_git_commit: alaveteli_git_commit,
        alaveteli_version: ALAVETELI_VERSION,
        ruby_version: RUBY_VERSION,
        visible_public_body_count: PublicBody.visible.count,
        visible_request_count: InfoRequest.is_searchable.count,
        private_request_count: InfoRequest.embargoed.count,
        confirmed_user_count: User.active.where(email_confirmed: true).count,
        visible_comment_count: Comment.visible.count,
        track_thing_count: TrackThing.count,
        widget_vote_count: WidgetVote.count,
        public_body_change_request_count: PublicBodyChangeRequest.count,
        request_classification_count: RequestClassification.count,
        visible_followup_message_count: OutgoingMessage.
          where(prominence: 'normal', message_type: 'followup').count
      }
    end

    def to_json(*)
      to_h.to_json
    end

    protected

    def alaveteli_git_commit
      `git log -1 --format="%H"`.strip
    end
  end
end
