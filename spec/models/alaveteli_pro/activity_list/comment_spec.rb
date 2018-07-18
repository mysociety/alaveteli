# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AlaveteliPro::ActivityList::Comment do
  include Rails.application.routes.url_helpers

  let!(:user){ FactoryBot.create(:user) }
  let!(:comment){ FactoryBot.create(:comment, :user => user) }
  let!(:event){ FactoryBot.create(:comment_event, :comment => comment) }
  let!(:activity){ described_class.new(event) }

  describe '#description' do

    it 'gives an appropriate description for a comment from someone else' do
      expect(activity.description).
        to eq '{{commenter_name}} added a new annotation on your request to ' \
              '{{public_body_name}} "{{info_request_title}}."'
    end


    it 'gives an appropriate description for a comment from the requester' do
      info_request = event.info_request
      info_request.user = comment.user
      info_request.save!
      expect(activity.description).
        to eq 'You added a new annotation on your request to ' \
              '{{public_body_name}} "{{info_request_title}}."'
    end
  end

  describe '#description_urls' do

    it 'returns a hash of :commenter_name, :public_body_name and
        :info_request_title' do
      expected_urls =
        {
         :commenter_name =>
            { :text => user.name,
              :url => user_path(user) },
          :public_body_name =>
            { :text => event.info_request.public_body.name,
              :url => public_body_path(event.info_request.public_body) },
          :info_request_title =>
            { :text => event.info_request.title,
              :url => request_path(event.info_request) }
        }
      expect(activity.description_urls).
        to eq expected_urls
    end

  end

  it_behaves_like "an ActivityList::Item with standard #call_to_action"

  describe '#call_to_action_url' do

    it 'returns the url of the comment' do
      expect(activity.call_to_action_url).
        to eq comment_path(comment)
    end

  end

end
