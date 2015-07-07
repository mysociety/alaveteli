# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ContactMailer do

    describe :to_admin_message do

        it 'correctly quotes the name in a "from" address' do
            ContactMailer.to_admin_message("A,B,C.",
                                           "test@example.com",
                                           "test",
                                           "test", nil, nil, nil)['from'].to_s.should == '"A,B,C." <test@example.com>'


        end

    end
end
