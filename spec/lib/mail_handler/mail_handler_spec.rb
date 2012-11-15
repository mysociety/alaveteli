# coding: utf-8
require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

describe 'when creating a mail object from raw data' do

    it 'should correctly parse a multipart email with a linebreak in the boundary' do
        mail = get_fixture_mail('space-boundary.email')
        mail.parts.size.should == 2
        mail.multipart?.should == true
    end

end
