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

end
