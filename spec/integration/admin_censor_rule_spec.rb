# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/alaveteli_dsl')

describe 'Adding an authority censor rule' do
  before do
    allow(AlaveteliConfiguration).to receive(:skip_admin_auth).and_return(false)

    confirm(:admin_user)
    @admin = login(:admin_user)
    @authority = FactoryGirl.create(:public_body)
  end

  it 'clears the cache for existing requests' do
    raw_email_data = <<-EOF.strip_heredoc
    From: authority@example.com
    To: Jane Doe <request-magic-email@example.net>
    Subject: A response

    I have a rubbish answer for you
    EOF

    request = FactoryGirl.create(:info_request, :public_body => @authority)
    incoming_message = FactoryGirl.create(:incoming_message,
                                          :info_request => request)
    incoming_message.raw_email.data = raw_email_data
    incoming_message.parse_raw_email!(true)
    InfoRequestEvent.create(:event_type => "response",
                            :incoming_message => incoming_message,
                            :info_request => request,
                            :params => {
                              :incoming_message_id => incoming_message.id
                            })


    visit show_request_path :url_title => request.url_title

    expect(page).to have_content "I have a rubbish answer for you"

    using_session(@admin) do
      visit new_admin_body_censor_rule_path(@authority)
      fill_in 'censor_rule_text', :with => 'a rubbish answer'
      fill_in 'censor_rule_replacement', :with => '[REDACTED]'
      fill_in 'censor_rule_last_edit_comment', :with => 'test'
      click_button 'Create'
    end

    visit show_request_path :url_title => request.url_title
    expect(page).not_to have_content "I have a rubbish answer for you"
    expect(page).to have_content "I have [REDACTED] for you"
  end

end
