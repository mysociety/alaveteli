# -*- encoding : utf-8 -*-

require 'spec_helper'

describe IncomingMessageError do

  describe '.new' do

    it 'requres a unique ID' do
      expect(IncomingMessageError.new).not_to be_valid
      expect(IncomingMessageError.new(:unique_id => 'xxx')).to be_valid
    end
  end

end
