# -*- encoding : utf-8 -*-
# == Schema Information
# Schema version: 20210114161442
#
# Table name: user_info_request_sent_alerts
#
#  id                    :integer          not null, primary key
#  user_id               :integer          not null
#  info_request_id       :integer          not null
#  alert_type            :string           not null
#  info_request_event_id :integer
#  created_at            :datetime
#  updated_at            :datetime
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

RSpec.describe UserInfoRequestSentAlert do
  it 'should allow an alert type of "survey_1"' do
    alert = UserInfoRequestSentAlert.new(alert_type: 'survey_1')
    expect(alert).to be_valid
  end
end
