require File.dirname(__FILE__) + '/../spec_helper'

describe "when making clickable" do

    it "should make URLs into links" do
        text = "Hello http://www.flourish.org goodbye"
        text = CGI.escapeHTML(text)
        formatted = MySociety::Format.make_clickable(text)
        formatted.should == "Hello <a href='http://www.flourish.org'>http://www.flourish.org</a> goodbye"
    end

    it "should make wrapped URLs in angle brackets clickable" do
        text = """<http://www.flou
rish.org/bl
og>

More stuff and then another angle bracket >"""
        text = CGI.escapeHTML(text)

        formatted = MySociety::Format.make_clickable(text)

        formatted.should == "&lt;<a href='http://www.flourish.org/blog'>http://www.flourish.org/blog</a>&gt;\n\nMore stuff and then another angle bracket &gt;"
    end

    it "should make wrapped URLs in angle brackets clickable" do
        text = """<https://web.nhs.net/owa/redir.aspx?C=25a8af7e66054d62a435313f7f3d4694&URL=h
ttp%3a%2f%2fwww.ico.gov.uk%2fupload%2fdocuments%2flibrary%2ffreedom_of_infor
mation%2fdetailed_specialist_guides%2fname_of_applicant_fop083_v1.pdf> Valid
request - name and address for correspondence 

If we can be of any further assistance please contact our Helpline on 08456
30 60 60 or 01625 545745 if you would prefer to call a national rate number,
quoting your case reference number. You may also find some useful
information on our website at
<https://web.nhs.net/owa/redir.aspx?C=25a8af7e66054d62a435313f7f3d4694&URL=h
ttp%3a%2f%2fwww.ico.gov.uk%2f> www.ico.gov.uk."""
        text = CGI.escapeHTML(text)
        formatted = MySociety::Format.make_clickable(text)

        expected_formatted = """&lt;<a href='https://web.nhs.net/owa/redir.aspx?C=25a8af7e66054d62a435313f7f3d4694&amp;URL=http%3a%2f%2fwww.ico.gov.uk%2fupload%2fdocuments%2flibrary%2ffreedom_of_information%2fdetailed_specialist_guides%2fname_of_applicant_fop083_v1.pdf'>https://web.nhs.net/owa/redir.aspx?C=25a8af7e66054d62a435313f7f3d4694&amp;URL=http%3a%2f%2fwww.ico.gov.uk%2fupload%2fdocuments%2flibrary%2ffreedom_of_information%2fdetailed_specialist_guides%2fname_of_applicant_fop083_v1.pdf</a>&gt; Valid
request - name and address for correspondence 

If we can be of any further assistance please contact our Helpline on 08456
30 60 60 or 01625 545745 if you would prefer to call a national rate number,
quoting your case reference number. You may also find some useful
information on our website at
&lt;<a href='https://web.nhs.net/owa/redir.aspx?C=25a8af7e66054d62a435313f7f3d4694&amp;URL=http%3a%2f%2fwww.ico.gov.uk%2f'>https://web.nhs.net/owa/redir.aspx?C=25a8af7e66054d62a435313f7f3d4694&amp;URL=http%3a%2f%2fwww.ico.gov.uk%2f</a>&gt; <a href='http://www.ico.gov.uk'>www.ico.gov.uk</a>."""

        formatted.should == expected_formatted
    end


end
