require 'spec_helper'
require "cancan/matchers"

RSpec.describe MailerAbility do
  let(:user) { FactoryBot.build(:user) }
  let(:ability) { MailerAbility.new(user) }

  describe 'EmbargoMailer#expiring_alert' do
    let(:name) { 'embargo_mailer#expiring_alert' }
    it { expect(ability).to be_able_to(:receive, name) }
  end

  describe 'EmbargoMailer#expired_alert' do
    let(:name) { 'embargo_mailer#expired_alert' }
    it { expect(ability).to be_able_to(:receive, name) }
  end

  describe 'SubscriptionMailer#payment_failed' do
    let(:name) { 'subscription_mailer#payment_failed' }
    it { expect(ability).to be_able_to(:receive, name) }
  end

  describe 'ContactMailer#user_message' do
    let(:name) { 'contact_mailer#user_message' }
    it { expect(ability).to be_able_to(:receive, name) }
  end

  describe 'ContactMailer#from_admin_message' do
    let(:name) { 'contact_mailer#from_admin_message' }
    it { expect(ability).to be_able_to(:receive, name) }
  end

  describe 'InfoRequestBatchMailer#batch_sent' do
    let(:name) { 'info_request_batch_mailer#batch_sent' }
    it { expect(ability).to be_able_to(:receive, name) }
  end

  describe 'NotificationMailer#daily_summary' do
    let(:name) { 'notification_mailer#daily_summary' }
    it { expect(ability).to be_able_to(:receive, name) }
  end

  describe 'NotificationMailer#response_notification' do
    let(:name) { 'notification_mailer#response_notification' }
    it { expect(ability).to be_able_to(:receive, name) }
  end

  describe 'NotificationMailer#embargo_expiring_notification' do
    let(:name) { 'notification_mailer#embargo_expiring_notification' }
    it { expect(ability).to be_able_to(:receive, name) }
  end

  describe 'NotificationMailer#expire_embargo_notification' do
    let(:name) { 'notification_mailer#expire_embargo_notification' }
    it { expect(ability).to be_able_to(:receive, name) }
  end

  describe 'NotificationMailer#overdue_notification' do
    let(:name) { 'notification_mailer#overdue_notification' }
    it { expect(ability).to be_able_to(:receive, name) }
  end

  describe 'NotificationMailer#very_overdue_notification' do
    let(:name) { 'notification_mailer#very_overdue_notification' }
    it { expect(ability).to be_able_to(:receive, name) }
  end

  describe 'RequestMailer#new_response' do
    let(:name) { 'request_mailer#new_response' }
    it { expect(ability).to be_able_to(:receive, name) }
  end

  describe 'RequestMailer#overdue_alert' do
    let(:name) { 'request_mailer#overdue_alert' }
    it { expect(ability).to be_able_to(:receive, name) }
  end

  describe 'RequestMailer#very_overdue_alert' do
    let(:name) { 'request_mailer#very_overdue_alert' }
    it { expect(ability).to be_able_to(:receive, name) }
  end

  describe 'RequestMailer#new_response_reminder_alert' do
    let(:name) { 'request_mailer#new_response_reminder_alert' }
    it { expect(ability).to be_able_to(:receive, name) }
  end

  describe 'RequestMailer#old_unclassified_updated' do
    let(:name) { 'request_mailer#old_unclassified_updated' }
    let(:ability) { MailerAbility.new(user, info_request: info_request) }

    context 'when info request when sent less than 6 months ago' do
      let(:info_request) { double(:InfoRequest, created_at: 6.months.ago + 1) }
      it { expect(ability).to be_able_to(:receive, name) }
    end

    context 'when info request when sent more than 6 months ago' do
      let(:info_request) { double(:InfoRequest, created_at: 6.months.ago) }
      it { expect(ability).not_to be_able_to(:receive, name) }
    end
  end

  describe 'RequestMailer#not_clarified_alert' do
    let(:name) { 'request_mailer#not_clarified_alert' }
    it { expect(ability).to be_able_to(:receive, name) }
  end

  describe 'RequestMailer#comment_on_alert' do
    let(:name) { 'request_mailer#comment_on_alert' }
    it { expect(ability).to be_able_to(:receive, name) }
  end

  describe 'RequestMailer#comment_on_alert_plural' do
    let(:name) { 'request_mailer#comment_on_alert_plural' }
    it { expect(ability).to be_able_to(:receive, name) }
  end

  describe 'SurveyMailer#survey_alert' do
    let(:name) { 'survey_mailer#survey_alert' }
    it { expect(ability).to be_able_to(:receive, name) }
  end

  describe 'TrackMailer#event_digest' do
    let(:name) { 'track_mailer#event_digest' }
    it { expect(ability).to be_able_to(:receive, name) }
  end

  describe 'UserMailer#confirm_login' do
    let(:name) { 'user_mailer#confirm_login' }
    it { expect(ability).to be_able_to(:receive, name) }
  end

  describe 'UserMailer#already_registered' do
    let(:name) { 'user_mailer#already_registered' }
    it { expect(ability).to be_able_to(:receive, name) }
  end

  describe 'UserMailer#changeemail_confirm' do
    let(:name) { 'user_mailer#changeemail_confirm' }
    it { expect(ability).to be_able_to(:receive, name) }
  end

  describe 'UserMailer#changeemail_already_used' do
    let(:name) { 'user_mailer#changeemail_already_used' }
    it { expect(ability).to be_able_to(:receive, name) }
  end
end
