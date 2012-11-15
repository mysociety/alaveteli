# coding: utf-8
require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

describe 'when creating a mail object from raw data' do

    it 'should correctly parse a multipart email with a linebreak in the boundary' do
        mail = get_fixture_mail('space-boundary.email')
        mail.parts.size.should == 2
        mail.multipart?.should == true
    end

    it 'should parse multiple to addresses with unqoted display names' do
        mail = get_fixture_mail('multiple-unquoted-display-names.email')
        mail.to.should == ["request-66666-caa77777@whatdotheyknow.com", "foi@example.com"]
    end

    it 'should convert an iso8859 email to utf8' do
        mail = get_fixture_mail('iso8859_2_raw_email.email')
        mail.subject.should have_text(/gjatë/u)
        mail.body.is_utf8?.should == true
    end

end
