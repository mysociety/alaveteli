# -*- encoding : utf-8 -*-
require 'spec_helper'
require File.expand_path(File.dirname(__FILE__) + '/alaveteli_dsl')

describe 'Editing the OutgoingMessage body' do

  let(:request) { FactoryBot.create(:info_request) }
  let(:ogm) { request.outgoing_messages.first }

  before do
    allow(AlaveteliConfiguration).to receive(:skip_admin_auth).and_return(false)

    confirm(:admin_user)
    @admin = login(:admin_user)
  end

  it 'saves the updated text' do
    using_session(@admin) do
      visit edit_admin_outgoing_message_path(ogm)
      fill_in 'outgoing_message_body', :with => 'Updated text'
      click_button 'Save'
    end

    expect(ogm.reload.body).to eq('Updated text')
  end

  context 'a censor rule applies to the request' do

    before do
      FactoryBot.create(:info_request_censor_rule,
                        text: 'information',
                        replacement: 'coffee',
                        info_request: request)
    end

    it 'displays the unredacted version of the message' do
      using_session(@admin) do
        visit edit_admin_outgoing_message_path(ogm)
        expect(page).to have_content('Some information please')
      end
    end

    it 'does not overwrite the raw_body content with redacted text' do
      using_session(@admin) do
        visit edit_admin_outgoing_message_path(ogm)
        fill_in 'outgoing_message_body',
                :with => 'Some information please. And a biscuit.'
        click_button 'Save'
      end

      ogm.reload
      expect(ogm.raw_body).to eq('Some information please. And a biscuit.')
      expect(ogm.body).to eq('Some coffee please. And a biscuit.')
    end

  end

end
