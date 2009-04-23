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

end
