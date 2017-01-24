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

  describe '#report_reasons' do

    let(:comment) { FactoryGirl.build(:comment) }

    it 'returns an array of strings' do
      expect(comment.report_reasons).to all(be_a(String))
    end

  end

end
