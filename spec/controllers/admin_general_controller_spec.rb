# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminGeneralController do

  describe "when viewing front page of admin interface" do

    render_views
    before { basic_auth_login @request }

    it "should render the front page" do
      get :index
      expect(response).to render_template('index')
    end

  end

  describe 'when viewing the timeline' do

    it 'should assign an array of events in order of descending date to the view' do

      info_request = FactoryGirl.create(:info_request)
      public_body = FactoryGirl.create(:public_body)

      first_event = info_request.log_event('edit', {})
      public_body.name = 'Changed name'
      public_body.save!
      public_body_version = public_body.reverse_sorted_versions.first
      second_event = info_request.log_event('edit', {})

      get :timeline, :all => 1

      expect(assigns[:events].first.first).to  eq(second_event)
      expect(assigns[:events].second.first).to eq(public_body_version)
      expect(assigns[:events].third.first).to eq(first_event)

    end

  end
end
