# -*- encoding : utf-8 -*-
require 'spec_helper'

describe 'when displaying actions that can be taken with regard to a request' do
  let(:info_request) { FactoryBot.create(:info_request) }
  let(:user) { info_request.user }
  let(:admin_user) { FactoryBot.create('admin_user') }

  let(:track_thing) do
    FactoryBot.create(:request_update_track, info_request: info_request)
  end

  let(:locals) do
    { info_request: info_request,
      track_thing: track_thing,
      last_response: nil,
      show_owner_update_status_action: nil,
      show_other_user_update_status_action: nil }
  end

  context 'if show_owner_update_status_action is true' do
    before { locals.merge(show_owner_update_status_action: true) }

    it 'displays a link for the request owner to update the status of the request' do
      render partial: 'request/after_actions', locals: locals

      expect(response.body).to have_css('ul.owner_actions') do |div|
        expect(div).to have_css('a', text: 'Update the status of this request')
      end
    end
  end

  context 'if show_owner_update_status_action is false' do
    before { locals.merge(show_owner_update_status_action: false) }

    it 'does not display a link for the request owner to update the status of the request' do
      render partial: 'request/after_actions', locals: locals

      expect(response.body).to have_css('ul.owner_actions') do |div|
        expect(div).
          not_to have_css('a', text: 'Update the status of this request')
      end
    end
  end

  context 'if show_other_user_update_status_action is true' do
    before { locals.merge(show_other_user_update_status_action: true) }

    it 'displays a link for anyone to update the status of the request' do
      render partial: 'request/after_actions', locals: locals

      expect(response.body).to have_css('ul.anyone_actions') do |div|
        expect(div).to have_css('a', text: 'Update the status of this request')
      end
    end
  end

  context 'if show_other_user_update_status_action is false' do
    before { locals.merge(show_other_user_update_status_action: false) }

    it 'does not display a link for anyone to update the status of the request' do
      render partial: 'request/after_actions', locals: locals

      expect(response.body).to have_css('ul.anyone_actions') do |div|
        expect(div).
          not_to have_css('a', text: 'Update the status of this request')
      end
    end
  end

  it 'displays a link for the request owner to request a review' do
    render partial: 'request/after_actions', locals: locals

    expect(response.body).to have_css('ul.owner_actions') do |div|
      expect(div).to have_css('a', text: 'Request an internal review')
    end
  end


  it 'displays the link to download the entire request' do
    render partial: 'request/after_actions', locals: locals

    expect(response.body).to have_css('ul.anyone_actions') do |div|
      text = 'Download a zip file of all correspondence'
      expect(div).to have_css('a', text: text)
    end
  end

  it 'displays a link to annotate the request' do
    with_feature_enabled(:annotations) do
      render partial: 'request/after_actions', locals: locals

      expect(response.body).to have_css('ul.anyone_actions') do |div|
        text = 'Add an annotation (to help the requester or others)'
        expect(div).to have_css('a', text: text)
      end
    end
  end

  it 'does not display a link to annotate the request if comments are disabled on it' do
    with_feature_enabled(:annotations) do
      info_request.comments_allowed = false

      render partial: 'request/after_actions', locals: locals

      expect(response.body).to have_css('ul.anyone_actions') do |div|
        text = 'Add an annotation (to help the requester or others)'
        expect(div).not_to have_css('a', text: text)
      end
    end
  end

  it 'does not display a link to annotate the request if comments are disabled globally' do
    with_feature_disabled(:annotations) do
      render partial: 'request/after_actions', locals: locals

      expect(response.body).to have_css('ul.anyone_actions') do |div|
        text = 'Add an annotation (to help the requester or others)'
        expect(div).not_to have_css('a', text: text)
      end
    end
  end

  context 'when the request has not been reported' do
    it 'displays a link to report it' do
      render partial: 'request/after_actions', locals: locals
      expect(response).to have_css('a', text: 'Report this request')
    end
  end

  context 'when the request has been reported' do
    it 'displays a link to the help page about why reporting is disabled' do
      info_request.report!('', '', nil)

      render partial: 'request/after_actions', locals: locals

      expect(response).not_to have_css('a', text: 'Report this request')

      expected_link = help_about_path(anchor: 'reporting_unavailable')
      expect(response).to have_link('Unavailable', href: expected_link)
    end
  end
end
