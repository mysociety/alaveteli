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
      @visible_request = FactoryBot.create(:info_request, :prominence => "normal")
      @hidden_request = FactoryBot.create(:info_request, :prominence => "hidden")
    end

    it 'should treat new comments to be visible by default' do
      comment = FactoryBot.create(:comment, :info_request => @visible_request)
      expect(@visible_request.comments.visible).to eq([comment])
    end

    it 'should treat comments which have be hidden as not visible' do
      comment = FactoryBot.create(:hidden_comment, :info_request => @visible_request)
      expect(@visible_request.comments.visible).to eq([])
    end

    it 'should treat visible comments attached to a hidden request as not visible' do
      comment = FactoryBot.create(:comment, :info_request => @hidden_request)
      expect(comment.visible).to eq(true)
      expect(@hidden_request.comments.visible).to eq([])
    end

  end

  describe '.embargoed' do

    before(:each) do
      @info_request = FactoryBot.create(:info_request)
      @request_comment = FactoryBot.create(:comment,
                                           :info_request => @info_request)
      @embargoed_request = FactoryBot.create(:embargoed_request)
      @embargoed_comment = FactoryBot.create(:comment,
                                             :info_request => @embargoed_request)
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
                                           :info_request => @info_request)
      @embargoed_request = FactoryBot.create(:embargoed_request)
      @embargoed_comment = FactoryBot.create(:comment,
                                             :info_request => @embargoed_request)
    end

    it 'does not include comments on embargoed requests' do
      expect(Comment.not_embargoed.include?(@embargoed_comment)).to be false
    end

    it "includes comments on requests without embargoes" do
      expect(Comment.not_embargoed.include?(@request_comment)).to be true
    end

  end

  describe '#hidden?' do

    it 'returns true if the comment is not visible' do
      comment = Comment.new(:visible => false)
      expect(comment.hidden?).to eq(true)
    end

    it 'returns false if the comment is visible' do
      comment = Comment.new(:visible => true)
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
      notification = ActionMailer::Base.deliveries.last
      expect(notification.subject).to eq(expected)
    end

    it 'prepends the reason to the message before sending' do
      expected = "Reason: Vexatious comment\n\nComment is bad, please hide"
      comment.report!("Vexatious comment", "Comment is bad, please hide", user)
      notification = ActionMailer::Base.deliveries.last
      expect(notification.body).to match(expected)
    end

    it "includes a note about the comment in the admin email" do
      expected =
        "The user wishes to draw attention to the comment: " \
        "#{comment_url(comment, :host => AlaveteliConfiguration.domain)}"
      comment.report!("Vexatious comment", "Comment is bad, please hide", user)
      notification = ActionMailer::Base.deliveries.last
      expect(notification.body).to match(expected)
    end

    it 'logs the report_comment event' do
      comment.info_request_events.
        where(:event_type => 'report_comment').destroy_all
      comment.report!("Vexatious comment", "Comment is bad, please hide", user)
      comment.reload
      most_recent_event = comment.info_request_events.last

      expect(most_recent_event.event_type).to eq('report_comment')
      expect(most_recent_event.params).
        to include(:reason => "Vexatious comment")
      expect(most_recent_event.params).
        to include(:message => "Comment is bad, please hide")
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
      comment.info_request.log_event("edit_comment",
                             { :comment_id => comment.id,
                               :editor => user,
                               :old_body => comment.body,
                               :body => 'fake change'
                             })
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

  describe 'for_admin_event_column' do

    let(:comment) { FactoryBot.create(:comment) }
    let(:user) { FactoryBot.create(:user) }

    it "returns nil unless passed an event" do
      # shouldn't happen but just in case
      expect(comment.for_admin_event_column(nil)).to be_nil
    end

    it "returns a subset of the event's for_admin_column data" do
      comment.report!("Vexatious comment", "reported", user)
      columns = comment.for_admin_event_column(comment.last_report) {
                  |name, value, type, column_name| }

      expect(columns[0].name).to eq("event_type")
      expect(columns[1].name).to eq("params_yaml")
      expect(columns[2].name).to eq("created_at")
    end

  end


end
