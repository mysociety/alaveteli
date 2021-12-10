require 'spec_helper'
require 'integration/alaveteli_dsl'

RSpec.describe 'Updating censor rules' do
  let!(:admin) do
    confirm(:admin_user)
    login(:admin_user)
  end

  let(:user) { FactoryBot.create(:user) }
  let(:authority) { FactoryBot.create(:public_body) }
  let(:request) do
    FactoryBot.create(:info_request,
                      :public_body => authority,
                      :user => user)
  end

  let!(:incoming_message) do
    raw_email_data = <<-EOF.strip_heredoc
    From: authority@example.com
    To: Jane Doe <request-magic-email@example.net>
    Subject: A response

    I have a rubbish answer for you
    EOF

    incoming_message = FactoryBot.create(:incoming_message,
                                         :info_request => request)
    incoming_message.raw_email.data = raw_email_data
    incoming_message.parse_raw_email!
    InfoRequestEvent.create(:event_type => "response",
                            :incoming_message => incoming_message,
                            :info_request => request,
                            :params => {
                              :incoming_message_id => incoming_message.id
                            })
    incoming_message
  end

  before do
    allow(AlaveteliConfiguration).to receive(:skip_admin_auth).and_return(false)
  end

  describe "Authority censor rules" do

    it 'clears the cache for existing requests when a new rule is added' do
      url_title = request.url_title
      visit show_request_path :url_title => url_title

      expect(page).to have_content "I have a rubbish answer for you"

      using_session(admin) do
        visit new_admin_body_censor_rule_path(authority)
        fill_in 'censor_rule_text', :with => 'a rubbish answer'
        fill_in 'censor_rule_replacement', :with => '[REDACTED]'
        fill_in 'censor_rule_last_edit_comment', :with => 'test'
        click_button 'Create'
      end

      visit show_request_path :url_title => url_title
      expect(page).not_to have_content "I have a rubbish answer for you"
      expect(page).to have_content "I have [REDACTED] for you"
    end

    it 'clears the cache for existing requests when a rule is updated' do
      url_title = request.url_title
      rule = FactoryBot.create(:public_body_censor_rule,
                               :public_body => authority,
                               :text => "rubbish",
                               :replacement => "[REDACTED]")

      visit show_request_path :url_title => url_title

      expect(page).to have_content "I have a [REDACTED] answer for you"

      using_session(admin) do
        visit edit_admin_censor_rule_path(rule.id)
        fill_in 'censor_rule_text', :with => 'answer'
        fill_in 'censor_rule_replacement', :with => '[REDACTED]'
        fill_in 'censor_rule_last_edit_comment', :with => 'test'
        click_button 'Save'
      end

      visit show_request_path :url_title => url_title
      expect(page).not_to have_content "I have a [REDACTED] answer for you"
      expect(page).to have_content "I have a rubbish [REDACTED] for you"
    end

    it 'clears the cache for existing requests when a rule is deleted' do
      url_title = request.url_title
      rule = FactoryBot.create(:public_body_censor_rule,
                               :public_body => authority,
                               :text => "rubbish",
                               :replacement => "[REDACTED]")

      visit show_request_path :url_title => url_title

      expect(page).to have_content "I have a [REDACTED] answer for you"

      using_session(admin) do
        visit edit_admin_censor_rule_path(rule.id)
        click_link 'Destroy censor rule'
      end

      visit show_request_path :url_title => url_title
      expect(page).not_to have_content "I have a [REDACTED] answer for you"
      expect(page).to have_content "I have a rubbish answer for you"
    end

  end

  describe "User censor rules" do

    it 'clears the cache for existing requests when a new rule is added' do
      url_title = request.url_title
      visit show_request_path :url_title => url_title

      expect(page).to have_content "I have a rubbish answer for you"

      using_session(admin) do
        visit new_admin_user_censor_rule_path(user)
        fill_in 'censor_rule_text', :with => 'a rubbish answer'
        fill_in 'censor_rule_replacement', :with => '[REDACTED]'
        fill_in 'censor_rule_last_edit_comment', :with => 'test'
        click_button 'Create'
      end

      visit show_request_path :url_title => url_title
      expect(page).not_to have_content "I have a rubbish answer for you"
      expect(page).to have_content "I have [REDACTED] for you"
    end

    it 'clears the cache for existing requests when a rule is updated' do
      url_title = request.url_title
      rule = FactoryBot.create(:user_censor_rule,
                               :user => user,
                               :text => "rubbish",
                               :replacement => "[REDACTED]")

      visit show_request_path :url_title => url_title

      expect(page).to have_content "I have a [REDACTED] answer for you"

      using_session(admin) do
        visit edit_admin_censor_rule_path(rule.id)
        fill_in 'censor_rule_text', :with => 'answer'
        fill_in 'censor_rule_replacement', :with => '[REDACTED]'
        fill_in 'censor_rule_last_edit_comment', :with => 'test'
        click_button 'Save'
      end

      visit show_request_path :url_title => url_title
      expect(page).not_to have_content "I have a [REDACTED] answer for you"
      expect(page).to have_content "I have a rubbish [REDACTED] for you"
    end

    it 'clears the cache for existing requests when a rule is deleted' do
      url_title = request.url_title
      rule = FactoryBot.create(:user_censor_rule,
                               :user => user,
                               :text => "rubbish",
                               :replacement => "[REDACTED]")

      visit show_request_path :url_title => url_title

      expect(page).to have_content "I have a [REDACTED] answer for you"

      using_session(admin) do
        visit edit_admin_censor_rule_path(rule.id)
        click_link 'Destroy censor rule'
      end

      visit show_request_path :url_title => url_title
      expect(page).not_to have_content "I have a [REDACTED] answer for you"
      expect(page).to have_content "I have a rubbish answer for you"
    end

  end

  describe "Request censor rules" do

    it 'clears the cache for existing requests when a new rule is added' do
      request_id = request.id
      url_title = request.url_title
      visit show_request_path :url_title => url_title

      expect(page).to have_content "I have a rubbish answer for you"

      using_session(admin) do
        visit new_admin_request_censor_rule_path(request_id)
        fill_in 'censor_rule_text', :with => 'a rubbish answer'
        fill_in 'censor_rule_replacement', :with => '[REDACTED]'
        fill_in 'censor_rule_last_edit_comment', :with => 'test'
        click_button 'Create'
      end

      visit show_request_path :url_title => url_title
      expect(page).not_to have_content "I have a rubbish answer for you"
      expect(page).to have_content "I have [REDACTED] for you"
    end

    it 'clears the cache for existing requests when a rule is updated' do
      request_id = request.id
      url_title = request.url_title
      rule = FactoryBot.create(:info_request_censor_rule,
                               :info_request => request,
                               :text => "rubbish",
                               :replacement => "[REDACTED]")

      visit show_request_path :url_title => url_title

      expect(page).to have_content "I have a [REDACTED] answer for you"

      using_session(admin) do
        visit edit_admin_censor_rule_path(rule.id)
        fill_in 'censor_rule_text', :with => 'answer'
        fill_in 'censor_rule_replacement', :with => '[REDACTED]'
        fill_in 'censor_rule_last_edit_comment', :with => 'test'
        click_button 'Save'
      end

      visit show_request_path :url_title => url_title
      expect(page).not_to have_content "I have a [REDACTED] answer for you"
      expect(page).to have_content "I have a rubbish [REDACTED] for you"
    end

    it 'clears the cache for existing requests when a rule is deleted' do
      request_id = request.id
      url_title = request.url_title
      rule = FactoryBot.create(:info_request_censor_rule,
                               :info_request => request,
                               :text => "rubbish",
                               :replacement => "[REDACTED]")

      visit show_request_path :url_title => url_title

      expect(page).to have_content "I have a [REDACTED] answer for you"

      using_session(admin) do
        visit edit_admin_censor_rule_path(rule.id)
        click_link 'Destroy censor rule'
      end

      visit show_request_path :url_title => url_title
      expect(page).not_to have_content "I have a [REDACTED] answer for you"
      expect(page).to have_content "I have a rubbish answer for you"
    end

  end

  describe "Global censor rules" do

    it 'clears the cache for existing requests when a new rule is added' do
      url_title = request.url_title
      visit show_request_path :url_title => url_title

      expect(page).to have_content "I have a rubbish answer for you"

      using_session(admin) do
        visit new_admin_censor_rule_path
        fill_in 'censor_rule_text', :with => 'a rubbish answer'
        fill_in 'censor_rule_replacement', :with => '[REDACTED]'
        fill_in 'censor_rule_last_edit_comment', :with => 'test'
        click_button 'Create'
      end

      visit show_request_path :url_title => url_title
      expect(page).not_to have_content "I have a rubbish answer for you"
      expect(page).to have_content "I have [REDACTED] for you"
    end

    it 'clears the cache for existing requests when a rule is updated' do
      url_title = request.url_title
      rule = FactoryBot.create(:global_censor_rule,
                               :text => "rubbish",
                               :replacement => "[REDACTED]")

      visit show_request_path :url_title => url_title

      expect(page).to have_content "I have a [REDACTED] answer for you"

      using_session(admin) do
        visit edit_admin_censor_rule_path(rule.id)
        fill_in 'censor_rule_text', :with => 'answer'
        fill_in 'censor_rule_replacement', :with => '[REDACTED]'
        fill_in 'censor_rule_last_edit_comment', :with => 'test'
        click_button 'Save'
      end

      visit show_request_path :url_title => url_title
      expect(page).not_to have_content "I have a [REDACTED] answer for you"
      expect(page).to have_content "I have a rubbish [REDACTED] for you"
    end

    it 'clears the cache for existing requests when a rule is deleted' do
      url_title = request.url_title
      rule = FactoryBot.create(:global_censor_rule,
                               :text => "rubbish",
                               :replacement => "[REDACTED]")

      visit show_request_path :url_title => url_title

      expect(page).to have_content "I have a [REDACTED] answer for you"

      using_session(admin) do
        visit edit_admin_censor_rule_path(rule.id)
        click_link 'Destroy censor rule'
      end

      visit show_request_path :url_title => url_title
      expect(page).not_to have_content "I have a [REDACTED] answer for you"
      expect(page).to have_content "I have a rubbish answer for you"
    end

  end

end
