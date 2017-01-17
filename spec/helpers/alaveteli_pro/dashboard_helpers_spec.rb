# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AlaveteliPro::DashboardHelper do

  include AlaveteliPro::DashboardHelper

  describe '#activity_item_description' do

    it 'renders the activity_item description with links' do
      user = FactoryGirl.create(:user)
      comment = FactoryGirl.create(:comment, :user => user)
      event = FactoryGirl.create(:comment_event, :comment => comment)
      activity = ActivityList::Comment.new(event)

      expected = "#{user_link user} added a new annotation on your request " \
                 "to #{public_body_link comment.info_request.public_body} " \
                 "\"#{request_link comment.info_request}.\""
      expect(activity_item_description(activity)).to eq expected
    end
  end

end
