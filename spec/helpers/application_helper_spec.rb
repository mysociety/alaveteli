# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ApplicationHelper do

  include ApplicationHelper
  include LinkToHelper

  describe '#can_ask_the_eu?' do

    it 'delegates to WorldFOIWebsites.can_ask_the_eu?' do
      expect(WorldFOIWebsites).to receive(:can_ask_the_eu?).with('US')
      can_ask_the_eu?('US')
    end

  end

  describe '#render_flash' do

    it 'returns a string when given a string' do
      expect(render_flash('some text')).to eq('some text')
    end

    it 'correctly resymbolizes the hash keys and calls render' do
      flash = { 'inline' => 'some text' }
      expect(render_flash(flash)).to eq('some text')
    end

  end

  describe '#read_asset_file' do

    it "raises an Exception if it can't find the file" do
      expect{ read_asset_file('nosuchfile.css') }.
        to raise_error(Sprockets::FileNotFound,
                       "Asset file 'nosuchfile.css' was not found in the " \
                       "assets directory")
    end

    it 'returns the contents of the file if it finds the asset' do
      expect(read_asset_file('responsive/application.css')).
        to match(/font-size/)
    end

    it 'returns the file content as UTF-8' do
      expect(read_asset_file('responsive/application.css').encoding.to_s).
        to eq('UTF-8')
    end

  end

  describe 'when creating an event description' do

    it 'should generate a description for a request' do
      @info_request = FactoryGirl.create(:info_request)
      @sent_event = @info_request.get_last_event
      expected = "Request sent to #{public_body_link_absolute(@info_request.public_body)} by #{request_user_link_absolute(@info_request)}"
      expect(event_description(@sent_event)).to match(expected)

    end

    it 'should generate a description for a response' do
      @info_request_with_incoming = FactoryGirl.create(:info_request_with_incoming)
      @response_event = @info_request_with_incoming.get_last_event
      expected = "Response by #{public_body_link_absolute(@info_request_with_incoming.public_body)} to #{request_user_link_absolute(@info_request_with_incoming)}"
      expect(event_description(@response_event)).to match(expected)
    end

    it 'should generate a description for a request where an internal review has been requested' do
      @info_request_with_internal_review_request = FactoryGirl.create(:info_request_with_internal_review_request)
      @response_event = @info_request_with_internal_review_request.get_last_event
      expected = "Internal review request sent to #{public_body_link_absolute(@info_request_with_internal_review_request.public_body)} by #{request_user_link_absolute(@info_request_with_internal_review_request)}"
      expect(event_description(@response_event)).to match(expected)
    end

  end

  describe 'site_wide_announcement' do
    let(:current_user) { FactoryGirl.create(:user) }

    it 'calls scopes on Announcement' do
      announcement = double(:announcement)
      relation = double(:announcement_relation)
      dismissal = double(:dismissal)
      session[:announcement_dismissals] = dismissal

      allow(Announcement).to receive(:site_wide_for_user).
        with(current_user, dismissal).
        and_return(relation)
      allow(relation).to receive(:first).
        and_return(announcement)

      expect(site_wide_announcement).to eq announcement
    end
  end

end
