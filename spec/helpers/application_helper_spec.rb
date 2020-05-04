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
      expect { read_asset_file('nosuchfile.css') }.
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

  describe '#theme_installed?' do

    let(:paths) { ['theme_path', 'app_path'] }

    let(:view_paths) { double(ActionView::PathSet, paths: paths) }

    it 'returns true if there is an installed theme' do
      expect(theme_installed?).to eq true
    end

    context 'no theme is installed' do

      let(:paths) { ['app_path'] }

      it 'returns false' do
        expect(theme_installed?).to eq false
      end

    end

  end

  describe '#theme_asset_exists?' do

    let(:theme_view_path) do
      File.dirname(__FILE__) + "/../../lib/themes/alavetelitheme/lib/views"
    end

    let(:app_view_path) { File.dirname(__FILE__) + "/../../app/views" }

    let(:paths) do
      [
        theme_view_path,
        app_view_path
      ]
    end

    let(:view_paths) { double(ActionView::PathSet, paths: paths) }

    it 'looks in the theme file path' do
      expected_path = theme_view_path.gsub('/lib/views', '/app/assets')
      allow(File).to receive(:exist?).and_call_original

      theme_asset_exists?('images/logo.png')
      expect(File).to have_received(:exist?).
        with(expected_path + "/images/logo.png")
    end

    it 'returns false if the file does not exist' do
      expect(theme_asset_exists?('images/imaginary.png')).to eq false
    end

    it 'returns true if the file exists' do
      expect(theme_asset_exists?('images/logo-opengraph.png')).to eq true
    end

    context 'without a theme installed' do

      let(:paths) { [ app_view_path ] }

      it 'looks in the core app file path' do
        expected_path = app_view_path.gsub('/app/views', '/app/assets')
        allow(File).to receive(:exist?).and_call_original

        theme_asset_exists?('images/logo.png')
        expect(File).to have_received(:exist?).
          with(expected_path + "/images/logo.png")
      end

      it 'returns true if the file exists' do
        expect(theme_asset_exists?('images/social-facebook.png')).to eq true
      end

    end

  end

  describe '#show_pro_upsell?' do
    subject { show_pro_upsell?(user) }

    context 'when the user is not logged in', feature: :alaveteli_pro do
      let(:user) { nil }
      it { is_expected.to eq(true) }
    end

    context 'when a regular user is logged in', feature: :alaveteli_pro do
      let(:user) { FactoryBot.create(:user) }
      it { is_expected.to eq(true) }
    end

    context 'when a pro user is logged in', feature: :alaveteli_pro do
      let(:user) { FactoryBot.create(:pro_user) }
      it { is_expected.to eq(false) }
    end

    context 'when pro is disabled' do
      let(:user) { FactoryBot.create(:user) }
      it { with_feature_disabled(:alaveteli_pro) { is_expected.to eq(false) } }
    end
  end

  describe '#pro_upsell_text' do
    subject { pro_upsell_text }

    let(:expected) do
      '<strong><a href="/pro">Alaveteli Professional</a></strong> is a ' \
      'powerful, fully-featured FOI toolkit for journalists.'
    end

    it { is_expected.to eq(expected) }
  end

  describe 'when creating an event description' do

    it 'should generate a description for a request' do
      @info_request = FactoryBot.create(:info_request)
      @sent_event = @info_request.last_event
      expected = "Request sent to #{public_body_link_absolute(@info_request.public_body)} by #{request_user_link_absolute(@info_request)}"
      expect(event_description(@sent_event)).to match(expected)

    end

    it 'should generate a description for a response' do
      @info_request_with_incoming = FactoryBot.create(:info_request_with_incoming)
      @response_event = @info_request_with_incoming.last_event
      expected = "Response by #{public_body_link_absolute(@info_request_with_incoming.public_body)} to #{request_user_link_absolute(@info_request_with_incoming)}"
      expect(event_description(@response_event)).to match(expected)
    end

    it 'should generate a description for a request where an internal review has been requested' do
      @info_request_with_internal_review_request = FactoryBot.create(:info_request_with_internal_review_request)
      @response_event = @info_request_with_internal_review_request.last_event
      expected = "Internal review request sent to #{public_body_link_absolute(@info_request_with_internal_review_request.public_body)} by #{request_user_link_absolute(@info_request_with_internal_review_request)}"
      expect(event_description(@response_event)).to match(expected)
    end

  end

  describe 'site_wide_announcement' do
    let(:current_user) { FactoryBot.create(:user) }

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
