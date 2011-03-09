require File.expand_path("../spec_helper", File.dirname(__FILE__))
require 'gettext_i18n_rails/string_interpolate_fix'

describe "String#%" do
  it "is not safe if it was not safe" do
    result = ("<br/>%{x}" % {:x => 'a'})
    result.should == '<br/>a'
    result.html_safe?.should == false
  end

  it "stays safe if it was safe" do
    result = ("<br/>%{x}".html_safe % {:x => 'a'})
    result.should == '<br/>a'
    result.html_safe?.should == true
  end

  it "escapes unsafe added to safe" do
    result = ("<br/>%{x}".html_safe % {:x => '<br/>'})
    result.should == '<br/>&lt;br/&gt;'
    result.html_safe?.should == true
  end

  it "does not escape unsafe if it was unsafe" do
    result = ("<br/>%{x}" % {:x => '<br/>'})
    result.should == '<br/><br/>'
    result.html_safe?.should == false
  end

  it "does not break array replacement" do
    "%ssd" % ['a'].should == "asd"
  end
end