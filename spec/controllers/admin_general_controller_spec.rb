# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminGeneralController do

  describe "GET #index" do

    before do
      InfoRequest.destroy_all
    end

    it "should render the front page" do
      get :index
      expect(response).to render_template('index')
    end

    it 'assigns old unclassified requests' do
      @old_request = FactoryGirl.create(:old_unclassified_request)
      get :index
      expect(assigns[:old_unclassified]).to eq([@old_request])
    end

    it 'assigns requests that require admin to the view' do
      requires_admin_request = FactoryGirl.create(:requires_admin_request)
      get :index
      expect(assigns[:requires_admin_requests]).to eq([requires_admin_request])
    end

    it 'assigns requests that have error messages to the view' do
      error_message_request = FactoryGirl.create(:error_message_request)
      get :index
      expect(assigns[:error_message_requests]).to eq([error_message_request])
    end

    it 'assigns requests flagged for admin attention to the view' do
      attention_requested_request = FactoryGirl.create(:attention_requested_request)
      get :index
      expect(assigns[:attention_requests]).to eq([attention_requested_request])
    end

  end

  describe 'GET #timeline' do

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
