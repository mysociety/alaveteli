# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: comments
#
#  id              :integer          not null, primary key
#  user_id         :integer          not null
#  info_request_id :integer
#  body            :text             not null
#  visible         :boolean          default(TRUE), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  locale          :text             default(""), not null
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Comment do

  describe 'visible scope' do
    before(:each) do
      @visible_request = FactoryGirl.create(:info_request, :prominence => "normal")
      @hidden_request = FactoryGirl.create(:info_request, :prominence => "hidden")
    end

    it 'should treat new comments to be visible by default' do
      comment = FactoryGirl.create(:comment, :info_request => @visible_request)
      expect(@visible_request.comments.visible).to eq([comment])
    end

    it 'should treat comments which have be hidden as not visible' do
      comment = FactoryGirl.create(:hidden_comment, :info_request => @visible_request)
      expect(@visible_request.comments.visible).to eq([])
    end

    it 'should treat visible comments attached to a hidden request as not visible' do
      comment = FactoryGirl.create(:comment, :info_request => @hidden_request)
      expect(comment.visible).to eq(true)
      expect(@hidden_request.comments.visible).to eq([])
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
      comment = FactoryGirl.create(:comment)
      events = comment.info_request_events
      comment.destroy
      events.select { |event| event.reload && event.persisted? }
      expect(events).to be_empty
    end

  end

  describe '#report!' do
    let(:comment) { FactoryGirl.create(:comment) }
    let(:user) { FactoryGirl.create(:user) }

    it 'sets attention_requested to true' do
      comment.report!("Vexatious comment", "Comment is bad, please hide", user)
      expect(comment.attention_requested).to eq(true)
    end

    it 'sends a message a message to admins' do
      message = double(RequestMailer)
      allow(RequestMailer).to receive(:requires_admin).and_return(message)
      expect(message).to receive(:deliver)
      comment.report!("Vexatious comment", "Comment is bad, please hide", user)
    end

    it 'prepends the reason to the message before sending' do
      message = double(RequestMailer)
      allow(message).to receive(:deliver)

      expected = "Reason: Vexatious comment\n\nComment is bad, please hide"
      expect(RequestMailer).to receive(:requires_admin).
        with(comment.info_request, user, expected).
        and_return(message)

      comment.report!("Vexatious comment", "Comment is bad, please hide", user)
    end

  end
end
