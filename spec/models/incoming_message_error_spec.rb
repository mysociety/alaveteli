# -*- encoding : utf-8 -*-
# == Schema Information
# Schema version: 20210114161442
#
# Table name: incoming_message_errors
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  unique_id  :string           not null
#  retry_at   :datetime
#  backtrace  :text
#

require 'spec_helper'

describe IncomingMessageError do

  describe '.new' do

    it 'requres a unique ID' do
      expect(IncomingMessageError.new).not_to be_valid
      expect(IncomingMessageError.new(:unique_id => 'xxx')).to be_valid
    end
  end

end
