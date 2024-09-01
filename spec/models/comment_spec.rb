# == Schema Information
# Schema version: 20220210114052
#
# Table name: comments
#
#  id                  :integer          not null, primary key
#  user_id             :integer          not null
#  info_request_id     :integer
#  body                :text             not null
#  visible             :boolean          default(TRUE), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  locale              :text             default(""), not null
#  attention_requested :boolean          default(FALSE), not null
#

require 'spec_helper'

RSpec.describe Comment do
  include Rails.application.routes.url_helpers
  include LinkToHelper

  describe '.visible' do
    before(:each) do
      @visible_request = FactoryBot.create(:info_request, prominence: "normal")
      @hidden_request = FactoryBot.create(:info_request, prominence: "hidden")
    end

    it 'should treat new comments to be visible by default' do
      comment = FactoryBot.create(:comment, info_request: @visible_request)
      expect(@visible_request.comments.visible).to eq([comment])
    end

    it 'should treat comments which have be hidden as not visible' do
      comment = FactoryBot.create(:hidden_comment, info_request: @visible_request)
      expect(@visible_request.comments.visible).to eq([])
    end

    it 'should treat visible comments attached to a hidden request as not visible' do
      comment = FactoryBot.create(:comment, info_request: @hidden_request)
      expect(comment.visible).to eq(true)
      expect(@hidden_request.comments.visible).to eq([])
    end
  end

  describe '.embargoed' do
    before(:each) do
      @info_request = FactoryBot.create(:info_request)
      @request_comment = FactoryBot.create(:comment,
                                           info_request: @info_request)
      @embargoed_request = FactoryBot.create(:embargoed_request)
      @embargoed_comment = FactoryBot.create(:comment,
                                             info_request: @embargoed_request)
    end

    it 'includes comments on embargoed requests' do
      expect(Comment.embargoed.include?(@embargoed_comment)).to be true
    end

    it "doesn't include comments on requests without embargoes" do
      expect(Comment.embargoed.include?(@request_comment)).to be false
    end
  end

  describe '.not_embargoed' do
    before(:each) do
      @info_request = FactoryBot.create(:info_request)
      @request_comment = FactoryBot.create(:comment,
                                           info_request: @info_request)
      @embargoed_request = FactoryBot.create(:embargoed_request)
      @embargoed_comment = FactoryBot.create(:comment,
                                             info_request: @embargoed_request)
    end

    it 'does not include comments on embargoed requests' do
      expect(Comment.not_embargoed.include?(@embargoed_comment)).to be false
    end

    it "includes comments on requests without embargoes" do
      expect(Comment.not_embargoed.include?(@request_comment)).to be true
    end
  end

  # rubocop:disable Layout/FirstArrayElementIndentation
  describe '.exceeded_creation_rate?' do
    subject { described_class.exceeded_creation_rate?(comments) }

    context 'when there are no comments' do
      let(:comments) { described_class.where(id: nil) }
      it { is_expected.to eq(false) }
    end

    context 'when the last comment was created in the last 2 seconds' do
      let(:comments) do
        described_class.where(id: [
          FactoryBot.create(:comment, created_at: 1.second.ago)
        ])
      end

      it { is_expected.to eq(true) }
    end

    context 'when the last comment was created a few seconds ago' do
      let(:comments) do
        described_class.where(id: [
          FactoryBot.create(:comment, created_at: 3.seconds.ago)
        ])
      end

      it { is_expected.to eq(false) }
    end

    context 'when the last 2 comments were created in the last 5 minutes' do
      let(:comments) do
        described_class.where(id: [
          FactoryBot.create(:comment, created_at: 1.second.ago),
          FactoryBot.create(:comment, created_at: 2.minutes.ago),
          FactoryBot.create(:comment, created_at: 3.days.ago)
        ])
      end

      it { is_expected.to eq(true) }
    end

    context 'when the last 4 comments were created in the last 30 minutes' do
      let(:comments) do
        described_class.where(id: [
          FactoryBot.create(:comment, created_at: 1.second.ago),
          FactoryBot.create(:comment, created_at: 2.minutes.ago),
          FactoryBot.create(:comment, created_at: 5.minutes.ago),
          FactoryBot.create(:comment, created_at: 10.minutes.ago),
          FactoryBot.create(:comment, created_at: 3.days.ago)
        ])
      end

      it { is_expected.to eq(true) }
    end

    context 'when the last 6 comments were created in the last hour' do
      let(:comments) do
        described_class.where(id: [
          FactoryBot.create(:comment, created_at: 1.second.ago),
          FactoryBot.create(:comment, created_at: 2.minutes.ago),
          FactoryBot.create(:comment, created_at: 5.minutes.ago),
          FactoryBot.create(:comment, created_at: 10.minutes.ago),
          FactoryBot.create(:comment, created_at: 40.minutes.ago),
          FactoryBot.create(:comment, created_at: 50.minutes.ago),
          FactoryBot.create(:comment, created_at: 3.days.ago)
        ])
      end

      it { is_expected.to eq(true) }
    end

    context 'when the comments are reasonably spaced' do
      let(:comments) do
        described_class.where(id: [
          FactoryBot.create(:comment, created_at: 15.minutes.ago),
          FactoryBot.create(:comment, created_at: 12.minutes.ago),
          FactoryBot.create(:comment, created_at: 40.minutes.ago),
          FactoryBot.create(:comment, created_at: 3.hours.ago),
          FactoryBot.create(:comment, created_at: 8.hours.ago),
          FactoryBot.create(:comment, created_at: 1.day.ago),
          FactoryBot.create(:comment, created_at: 3.days.ago)
        ])
      end

      it { is_expected.to eq(false) }
    end

    context 'when the comments are provided out of order' do
      let(:comments) do
        described_class.where(id: [
          FactoryBot.create(:comment, created_at: 3.days.ago),
          FactoryBot.create(:comment, created_at: 2.minutes.ago),
          FactoryBot.create(:comment, created_at: 1.second.ago)
        ]).order(created_at: :asc)
      end

      it { is_expected.to eq(true) }
    end
  end
  # rubocop:enable Layout/FirstArrayElementIndentation

  describe '.cached_urls' do
    it 'includes the correct paths' do
      comment = FactoryBot.create(:comment)
      request_path = "/request/" + comment.info_request.url_title
      user_wall_path = "/user/" + comment.user.url_name + "/wall"
      expect(comment.cached_urls).to eq([request_path, user_wall_path])
    end
  end

  describe '#prominence' do
    subject { comment.prominence }

    context 'when the comment is visible' do
      let(:comment) { described_class.new(visible: true) }
      it { is_expected.to eq('normal') }
    end

    context 'when the comment is hidden' do
      let(:comment) { described_class.new(visible: false) }
      it { is_expected.to eq('hidden') }
    end
  end

  describe '#hidden?' do
    it 'returns true if the comment is not visible' do
      comment = Comment.new(visible: false)
      expect(comment.hidden?).to eq(true)
    end

    it 'returns false if the comment is visible' do
      comment = Comment.new(visible: true)
      expect(comment.hidden?).to eq(false)
    end
  end

  describe '#destroy' do
    it 'destroys the associated info_request_events' do
      comment = FactoryBot.create(:comment)
      events = comment.info_request_events
      comment.destroy
      events.select { |event| event.reload && event.persisted? }
      expect(events).to be_empty
    end
  end

  describe '#report_reasons' do
    let(:comment) { FactoryBot.build(:comment) }

    it 'returns an array of strings' do
      expect(comment.report_reasons).to all(be_a(String))
    end
  end

  describe '#report!' do
    let(:comment) { FactoryBot.create(:comment) }
    let(:user) { FactoryBot.create(:user) }

    it 'sets attention_requested to true' do
      comment.report!("Vexatious comment", "Comment is bad, please hide", user)
      expect(comment.attention_requested).to eq(true)
    end

    it 'sends a message a message to admins' do
      expected = "FOI response requires admin (waiting_response) " \
                 "- #{comment.info_request.title}"
      comment.report!("Vexatious comment", "Comment is bad, please hide", user)
      notification = deliveries.last
      expect(notification.subject).to eq(expected)
    end

    it 'prepends the reason to the message before sending' do
      expected = "Reason: Vexatious comment\n\nComment is bad, please hide"
      comment.report!("Vexatious comment", "Comment is bad, please hide", user)
      notification = deliveries.last
      expect(notification.body).to match(expected)
    end

    it "includes a note about the comment in the admin email" do
      expected =
        "The user wishes to draw attention to the comment: " \
        "#{comment_url(comment, host: AlaveteliConfiguration.domain)}"
      comment.report!("Vexatious comment", "Comment is bad, please hide", user)
      notification = deliveries.last
      expect(notification.body).to match(expected)
    end

    it 'logs the report_comment event' do
      comment.info_request_events.
        where(event_type: 'report_comment').destroy_all
      comment.report!("Vexatious comment", "Comment is bad, please hide", user)
      comment.reload
      most_recent_event = comment.info_request_events.last

      expect(most_recent_event.event_type).to eq('report_comment')
      expect(most_recent_event.params).
        to include(reason: "Vexatious comment")
      expect(most_recent_event.params).
        to include(message: "Comment is bad, please hide")
    end
  end

  describe '#last_report' do
    let(:comment) { FactoryBot.create(:comment) }
    let(:user) { FactoryBot.create(:user) }

    it 'returns nil if there is no report' do
      expect(comment.last_report).to be_nil
    end

    it 'returns the last report event' do
      comment.report!("Vexatious comment", "report", user)
      comment.info_request.log_event(
        'edit_comment',
        comment_id: comment.id,
        editor: user,
        old_body: comment.body,
        body: 'fake change'
      )
      comment.reload

      expect(comment.info_request_events.last.event_type).to eq("edit_comment")
      expect(comment.last_report.event_type).to eq("report_comment")
    end
  end

  describe '#last_reported_at' do
    let(:comment) { FactoryBot.create(:comment) }
    let(:user) { FactoryBot.create(:user) }

    it 'returns nil if there is no report' do
      expect(comment.last_reported_at).to be_nil
    end

    it 'returns the expected timestamp' do
      expected = DateTime.now
      comment.report!("Vexatious comment", "reported", user)
      expect(comment.reload.last_reported_at).
        to be_within(3.seconds).of(expected)
    end
  end

  describe '#hide' do
    subject { comment.hide(editor: editor) }

    let(:comment) { FactoryBot.create(:comment) }
    let(:editor) { FactoryBot.create(:user, :admin) }

    it 'hides the comment' do
      subject
      expect(comment).not_to be_visible
    end

    it 'logs an event on the request' do
      expect(NotifyCacheJob).to receive(:perform_later).with(comment)
      subject
      event = comment.info_request.last_event
      expect(event.event_type).to eq('hide_comment')
      expect(event.params[:comment]).to eq(comment)
      expect(event.params[:editor]).to eq(editor.url_name)
      expect(event.params[:old_visible]).to eq(true)
      expect(event.params[:visible]).to eq(false)
    end
  end

  describe '#destroy_and_log_event' do
    let(:comment) { FactoryBot.create(:comment) }

    def last_event
      comment.info_request.info_request_events.last
    end

    it 'destroy and logs destroy_comment event' do
      expect(comment).to receive(:destroy).and_call_original

      expect do
        comment.destroy_and_log_event
      end.to change { last_event }

      expect(last_event.event_type).to eq('destroy_comment')
    end

    it 'logs key comment attributes' do
      comment.destroy_and_log_event

      expect(last_event.comment).to be_nil
      expect(last_event.params).to include(
        comment: { gid: comment.to_gid.to_s },
        comment_user: { gid: comment.user.to_gid.to_s },
        comment_created_at: comment.created_at.utc.iso8601(3),
        comment_updated_at: comment.updated_at.utc.iso8601(3)
      )
    end

    it 'logs additional event data' do
      comment.destroy_and_log_event(event: { editor: 'me' })
      expect(last_event.params).to include(editor: 'me')
    end

    it 'does not log event if update fails' do
      allow(comment).to receive(:destroy).and_return(false)
      expect do
        comment.destroy_and_log_event
      end.to_not change { last_event }
    end
  end
end
