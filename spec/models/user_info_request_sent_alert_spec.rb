# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: user_info_request_sent_alerts
#
#  id                    :integer          not null, primary key
#  user_id               :integer          not null
#  info_request_id       :integer          not null
#  alert_type            :string(255)      not null
#  info_request_event_id :integer
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe UserInfoRequestSentAlert, " when blah" do
    before do
    end
end


